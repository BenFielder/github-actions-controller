<h1> Github Actions Controller </h1>

Github-actions-controller is designed as a central place for github workflows to be managed from. This ranges from linting, testing, building and deploying workflows for code.

Think of it like a easy quick way to get setup with basic workflows, and if you wanted to update them across multiple repositories, this is the place to do so! As its intended as the central place to manage them, rather than going into each repo and updating them one at a time.

<h2> How do I get started? </h2>
Simply inside your repository setup a workflow file, similar to the below example.

```
name: Github Actions Controller
on: workflow_dispatch

permissions:
  contents: write
  pull-requests: write
  issues: write
  repository-projects: write
  actions: write

jobs:
    Update-deployment-workflow:
        runs-on: ubuntu-latest
        steps:
           - name: Pull workflows
             uses: BenFielder/github-actions-controller@<Your chosen version here>
             with:
                testing_workflows: true
                linting_workflows: true
                build_workflows: true
                deployment_workflows: true
                github_token: ${{ secrets.GITHUB_TOKEN }}
```

<h2> What arguments can I set? </h2>
The workflow has four different arguments that can be set, as seen in the above example, you can set:

- testing_workflows &rarr; This will pull in workflows to test your code, think Jest or Pytest
- linting_workflows &rarr; This will pull in workflows to lint your code, such as Pylint other linting tools!
- build_workflows &rarr; This will pull in workflows to build your code, npm etc
- deployment_workflows &rarr; Finally this will get deployment workflows for you to deploy your code somewhere.

You need to provide your github token/an automated github token in order for it to create pull requests in the repository it is being ran in.
