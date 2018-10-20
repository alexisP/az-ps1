az-ps1 displays your subscription in your prompt
================================================

When dealing with multiple Azure subcriptions, it quickly become difficult to know which subscription is the active one and you can easily make mistakes. This simple script helps you by displaying the current Azure subscription right in your prompt.

It is supported on both bash and zsh prompts.

![Demo](images/az-ps1-prompt.gif)

## Installing

**From Source**

1. Clone this repository (or download only the script)
2. Source the az-ps1.sh in your `~/.zshrc` or your `~/.bashrc`

Zsh:
```sh
source /path/to/az-ps1.sh
PROMPT='$(az_ps1)'$PROMPT
```

Bash:
```sh
source /path/to/az-ps1.sh
PS1='[\u@\h \W $(az_ps1)]\$ '
```

## Requirements

This script has a dependency on the Azure CLI 2.0 which needs to be installed as a prerequisite (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

There are two ways to get the current subcription name:
1. from the Azure CLI itself
2. from local files that stores the information

The second option is much more faster and will be the privileged option but it requires an additional prerequisite to work: JQ which is used to parse and query the local JSON files (https://stedolan.github.io/jq/). Simply install JQ and the script will use it by default and will be faster.

## Enabling/Disabling

If you want to stop showing the current subscription on your prompt string temporarily
run `azoff`. To disable the prompt for all shell sessions, run `azoff -g`.
You can enable it again in the current shell by running `azon`, and globally
with `azon -g`.

```
azon     : turn on az-ps1 status for this shell.  Takes precedence over
             global setting for current session
azon -g  : turn on az-ps1 status globally
azoff    : turn off az-ps1 status for this shell. Takes precedence over
             global setting for current session
azoff -g : turn off az-ps1 status globally
```

## Customization

The default settings can be overridden in `~/.bashrc` or `~/.zshrc` by setting
the following environment variables:

| Variable | Default | Meaning |
| :------- | :-----: | ------- |
| `AZ_PS1_BINARY` | `az` | Default Azure CLI binary |
| `AZ_PS1_JQ_BINARY` | `jq` | Default JQ binary |
| `AZ_PS1_PREFIX` | `(` | Prompt opening character  |
| `AZ_PS1_SUFFIX` | `)` | Prompt closing character |

To disable a feature, set it to an empty string:

```
AZ_PS1_SUFFIX=''
```

## Colors

The default colors are set with the following environment variables:

| Variable | Default | Meaning |
| :------- | :-----: | ------- |
| `AZ_PS1_SUBSCRIPTION_COLOR` | `red` | Set default color of the cluster context |
| `AZ_PS1_BG_COLOR` | `null` | Set default color of the prompt background |


Set the variable to an empty string if you do not want color for each
prompt section:

```
AZ_PS1_SUBSCRIPTION_COLOR=''
```

Names are usable for the following colors:

```
black, red, green, yellow, blue, magenta, cyan
```

256 colors are available by specifying the numerical value as the variable
argument.

## Tips & Tricks

If, like me, you are using Oh My Zsh with the agnoster theme and the Solarized Dark colorscheme, you probably want to set the backgroud color like so (in your `$HOME/.zshrc`) to make it clean
```
AZ_PS1_BG_COLOR=#586e75
```

## Credits

This script has been inspired by Jon Mosco's prompt helper for Kubernetes (https://github.com/jonmosco/kube-ps1). As a regular user of both Azure and Kubernetes, I thought that Azure deserves the same kind of helper to ease multiple subscriptions management.
