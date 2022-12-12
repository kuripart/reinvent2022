# Operating highly available Multi-AZ application

## Source of failure:

- Single server failure
- Single deployment
- Single config change
- Local network failure
- Infrastructure failure
- Power failure
- Flood
- Storage limits
- Heap mem exceeded
- Storage limits
- TLS cert expiry
- Customer traffic/DoS
- Storage
- Dependency


## Hard failures:

These come to mind easily:

- Unresponsive host
- Unresponsive LB
- Unresponsive AZ


## Grey failures

Hard to detect

Example: Service X is up, but slow/intermittent/sporadically times out

Cause:

- Software bug
- Faulty config change
- Reduced capacity

Health check may miss these.

Hard failures -> Impactful + Fast to detect and mitigate
Grey failures -> Impact could be greater BUT eludes detection and mitigation


Strategies to deal with Greys:


- Adopt deep health check pattern: 
https://www.oreilly.com/library/view/implementing-cloud-design/9781782177340/ch03s04.html
https://aws.amazon.com/builders-library/implementing-health-checks/

Update the logic of the LB's heatlh check handler to more thoroughly exercise host and application health

Pros:

- Relatively cheaper to implement

Cons:

- Overreaction risk, taking out capacity inappropriately
- Unlikely to detect a grey failure


- Set ELB minimum healthy target count

Situation:

Suppose 2 of 3 hosts fall in AZ3

- Equal load to all 3 AZs
- AZ3 will be overwhelmed

ELB supports a minimum healthy target count
Turns a grey failure into hard failure

- Detect and shift away from zone


Turn a wide array of gray failures into hard failure: "One zonal replica is out of service"

Strategy used widely within AWS

- Turn off cross-zone load balancing: eases detection and reduces cross-AZ interactions
- Monitor pre-AZ customer experience and compare
- Detect and shift work away from zonal replica

More on shifting away from a zone:

- Route 53 Application Recovery Controller zonal shift

-- Temporarily shift load away from one zone through an API call

Sample call example:

![Sample CMD](./images/start-zonal-shift-cmd.png)

Before:

![Traffic to application](./images/lb-app-part-1.gif)

After:

![Zonal shift in action](./images/lb-app-part-2.gif)