# Devops Infra Optimization


**Background of the problem statement:**
A popular payment application, EasyPay where users add money to their wallet accounts, faces an issue in its payment success rate. The timeout that occurs with
the connectivity of the database has been the reason for the issue.
While troubleshooting, it is found that the database server has several downtime instances at irregular intervals. This situation compels the company to create their own infrastructure that runs in high-availability mode.
Given that online shopping experiences continue to evolve as per customer expectations, the developers are driven to make their app more reliable, fast, and secure for improving the performance of the current system.

**Implementation requirements:**

1. Create the cluster (EC2 instances with load balancer and elastic IP in case of AWS)
1. Automate the provisioning of an EC2 instance using Ansible or Chef Puppet
1. Install Docker and Kubernetes on the cluster
1. Implement the network policies at the database pod to allow ingress traffic from the front-end application pod
1. Create a new user with permissions to create, list, get, update, and delete pods
1. Configure application on the pod
1. Take snapshot of ETCD database
1. Set criteria such that if the memory of CPU goes beyond 50%, environments automatically get scaled up and configured

**The following tools must be used:**

1. EC2
1. Kubernetes
1. Docker
1. Ansible or Chef or Puppet

**The following things to be kept in check:**

1. You need to document the steps and write the algorithms in them.
1. The submission of your GitHub repository link is mandatory. In order to track your tasks, you need to share the link of the repository.
1. Document the step-by-step process starting from creating test cases, then executing them, and recording the results.
1. You need to submit the final specification document, which includes:

* Project and tester details
* Concepts used in the project
* Links to the GitHub repository to verify the project completion
* Your conclusion on enhancing the application and defining the USPs (Unique Selling Points)
