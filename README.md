# WordPress SSH Git CI

**Creator:** Ryan Valizan -- [@devnetkc](https://github.com/devnetkc)  
**Latest Release:** [v1.0.1](https://github.com/devnetkc/wordpress-ssh-git-ci/releases/tag/v1.0.1)  
**Tags:** git, WordPress, Bash, ci, Azure Azure DevOps, SiteGround, SSH, Azure Pipeline  
**License:** GPLv3  
**License URI:** [https://www.gnu.org/licenses/gpl-3.0.en.html](https://www.gnu.org/licenses/gpl-3.0.en.html)  

## Description

### ✨ Automate your WordPress and git repository release pipeline

If there's SSH & Git, you can sync WordPress and Azure DevOps using git.

Let your CI Pipeline manage getting those plugin updates from your unix WordPress server.  

#### Live WordPress Branch History

![AzureHistory](https://raw.githubusercontent.com/devnetkc/readme-assets/master/Images/WordPress-commit-history.png)

### How To Use

````cmd
bash ~/wp-git-sync.sh \
  -b sgLive \
  -d sgStage \
  -g $(DevOpsHost)wordpress-ssh-git-ci \
  -p /home/username/public_html/wp-git-sync \
  -t $(DevOpsToken) \
  -u $(DevOpsTokenUser)
````

More information on the [arguments](https://github.com/devnetkc/wordpress-ssh-git-ci/wiki/How-To-Use#arguments) is available on the [WIKI](https://github.com/devnetkc/wordpress-ssh-git-ci/wiki) page [__How to Use__](https://github.com/devnetkc/wordpress-ssh-git-ci/wiki/How-To-Use)

#### Azure Pipeline

YAML Example:  
*note: This example uses Azure Key store variables*

````yaml
steps:
- task: SSH@0
  displayName: pushChanges
  inputs:
    sshEndpoint: 'agent-to-siteground'
    commands: 'bash ~/wp-git-sync.sh \
    -b sgLive \
    -d sgStage \
    -g $(DevOpsHost)wordpress-ssh-git-ci \
    -p /home/username/public_html/wp-git-sync \
    -t $(DevOpsToken) \
    -u $(DevOpsTokenUser)'
````

Classic Editor Example:

![PipelineScreen](https://raw.githubusercontent.com/devnetkc/readme-assets/master/Images/Azure-Pipeline-Example.png)

Console Log:

![WordPress-SSH-Git-CI](https://user-images.githubusercontent.com/26221344/91645717-0eae4d80-ea0d-11ea-81d9-b1e072766767.png)

<!-- markdownlint-disable -->
#### Requirements:
<!-- markdownlint-restore -->

- **Web server have git capability** -- think this is the most important one
- A method to store your secrete variables such as
  - username
  - password/token
- SSH access to execute scripts on WordPress server
  - *note: `cron` can serve as a slower alternative to SSH*
- Some kind of CI pipeline or `cron` job to hook into after a branch update event triggers an agent to run the script remotely

<!-- markdownlint-disable -->
#### What it has:
<!-- markdownlint-restore -->

- Parameter options for dynamic use
- Separated functions
- Is executed through an ssh call to your WordPress web server

<!-- markdownlint-disable -->
#### What it does is:
<!-- markdownlint-restore -->

- Check a git repo on a WordPress web server for changes
- Stashes changes before working on merges
- Pulls in latest release/master branch from development repository — on Azure DevOps, GitHub, BitBucket, etc.
- Merges new changes from DevOps into WordPress Live branch
- Returns WordPress updates and changes using git stash pop
- Commits the new changes on top of the latest master branch head
- Pushes WordPress live branch back to the development repository for the team to handle PR to DevOps master.

---

Essentially, it allows WordPress developers to be more hands off with their shared hosting WordPress server backends, while still fully benefitting from any of the many source control repository and project board sites for git — but while using WordPress at the same time.

## Contributing

Contrabutions are welcome!

### Getting Started

#### [Kanban Roadmap Board](https://github.com/devnetkc/wordpress-ssh-git-ci/projects/1)

This is a simple script project to automate a painful manual process I dealt with every day at the office. This gets a WordPress git repository on a unix server and Azure DevOps to play nice with one another.

If you see some adjustments to make, by all means suggest them.  This needs some clean up and refactoring yet.

New issues or requests will be tracked on the [kanban board](https://github.com/devnetkc/wordpress-ssh-git-ci/projects/1) for the project.

#### Emoji's in commits

Emoji guide can be found here on the [gimoji project site](https://gitmoji.carloscuesta.me/).  Choose an emoji from the list provided above that fitst the fix or change you are submitting

#### Submitting a pull request

1) Fork the repository [wordpress-ssh-git-ci](https://github.com/devnetkc/wordpress-ssh-git-ci)
2) Create a new branch off of [master](https://github.com/devnetkc/wordpress-ssh-git-ci/tree/master)
3) Make your changes
   - Commit messages not as important, but will help you in making your PR
4) Create a [Pull Request](https://github.com/devnetkc/wordpress-ssh-git-ci/pulls) for your change into [master](https://github.com/devnetkc/wordpress-ssh-git-ci/tree/master)
   - First line is `:emoji_name: what this pr does` > 100 characters
   - In the description include all commit messages as changes -- the squash is coming

It is also recommended to keep your pull request down to one specific issue or feature at a time.

## WIKI & FAQ

A [WIKI](https://github.com/devnetkc/wordpress-ssh-git-ci/wiki/) is available for the project and is moderatly managed.

[FAQ information](https://github.com/devnetkc/wordpress-ssh-git-ci/wiki/FAQ) can be found [here](https://github.com/devnetkc/wordpress-ssh-git-ci/wiki/FAQ).
