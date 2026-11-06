# nginx on ECS Fargate — Terragrunt, dev + prod

Nginx is behind an ALB, reads one secret, reaches an existing Redis in another VPC.
Local backend setup atm, there is commented S3 one edit away in `root.hcl`, so it plans with no prerequisites.

## Layout

```
root.hcl                 backend + AWS provider, included by each env
_modules/app_stack/      one module, split per resource:
  vpc.tf                 VPC, subnets, NAT, routes
  security-groups.tf     alb + tasks SGs
  alb.tf                 ALB + target group + listener (community module commented)
  ecs.tf                 cluster, task def, service, IAM roles, logs
  redis.tf               peering + route + ingress to the external Redis
  secret.tf              secret referenced by ARN (notes only)
  autoscaling.tf         Application Auto Scaling policies
  variables.tf / outputs.tf / versions.tf
dev/ , prod/             env.hcl (values) + terragrunt.hcl (identical between envs)
```

## Plan

```
cd dev  && terragrunt plan
cd prod && terragrunt plan
```

Needs AWS creds (the provider validates). State is local — nothing to pre-create.

## Create vs reference

- Create: VPC, subnets, NAT, ALB, ECS service, autoscaling, our SGs, the peering  to the Redis VPC and the Redis ingress rule.
- Reference: Redis (endpoint/VPC/CIDR/SG) and the secret ARN come in as variables, placeholders in `env.hcl`. The task puts them somewhere else, so I pass them in  rather than create them.
`redis.tf` and `secret.tf` each keep a commented `data` block (`aws_elasticache_replication_group`, `aws_secretsmanager_secret`) showing how I would reference them instead of hard-coding the values.

## Redis — assumption

The task says that app connects to Redis, and that "no code is required", so I assume that Redis already exists, so it is not created here.
Its assumed to sit in a separate VPC in the same region. We peer to that VPC, route to its CIDR, and open the Redis port on its SG from our VPC CIDR. A busybox sidecar `nc`-probes the endpoint and logs the result — proof the path (routing + SGs) is open.

Ingress always lives on the target's SG, so that rule is written against the Redis SG
I assume that in a real setup it should be added from the Redis side. Peering should presumable also be done from the same side that does the Redis VPC.

## Secret — assumption

Its assumed that secret is pre-existing, so its referenced by ARN. The ECS execution role gets GetSecretValue on that one ARN and injects it at container start.

## Autoscaling

I have added 3 types of autoscaling, by CPU/Memory/Request count.
All 3 types have "knobs" to be turned on/off as needed.
My assumption is, since I have used nginx as an example for web app, or gateway that it is probably cpu/req intensive.
I have used request-count scaling as an real world example where fine tunning makes most sense.

Request-count scaling differs by env: dev uses target tracking and lets AWS own the alarms, and prod uses step scaling so scale-out fires on a 1-minute alarm (+1, or +2 on a big spike) and scale-in only after 15 minutes. Basically on prod rapid scale-out, slow scale-in.


## prod vs dev

| | dev | prod |
|---|---|---|
| AZs / NAT | 2 / 1 shared | 3 / 1 per AZ |
| tasks min–max | 1–2 | 3–10 |
| task cpu/mem | 256/512 | 512/1024 |
| request scaling | target tracking | step (fast out / slow in) |
| insights / logs | off / 7d | on / 30d |

Both `terragrunt.hcl` are identical; all divergence is data in `env.hcl`.

## Trade-offs

- Local backend active, S3 commented (its bucket + lock table must pre-exist).
- One bundled module — simple, couples lifecycle/state.
I gave an example that we could use community modules on ALB, same thing can be done for other modules, VPC would probably biggest save on code lenght and visibilty. Community modules are good for visibility and ease of setup IMHO, but my experience shows that for modules you need to keep track of versions and make sure to adapt your code in time to match the state file and actual state on the platform.
- HTTP-only ALB (no domain/ACM).
- Redis ingress rule + peering kept in this stack for the demo, real owning of this should be on Redis/platform side.

## What would I add

- HTTPS 
- CI/CD that would deploy the actual app here instead of Terraform for image deployment. Task definition has been ignored via terraform, so replacing the image would not cause replacement or change of resource in next terraform/terragrunt run.