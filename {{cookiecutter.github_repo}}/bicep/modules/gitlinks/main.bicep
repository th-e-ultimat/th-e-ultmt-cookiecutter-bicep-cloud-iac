targetScope = 'subscription'


param userDalId string
param b2cHelpersId string
param articleDalId string
param deviceDalId string
param userLaId string
param deviceLaId string
param sharedDeviceLaId string

output links array = [
  {
    resourceId: userDalId
    repoUrl: 'https://github.com/{{cookiecutter.git_org}}/{{cookiecutter.git_repo_pref}}-func-user-dal'
  }
  {
    resourceId: b2cHelpersId
    repoUrl: 'https://github.com/{{cookiecutter.git_org}}/{{cookiecutter.git_repo_pref}}-func-aadb2c-helpers'
  }
  {
    resourceId: articleDalId
    repoUrl: 'https://github.com/{{cookiecutter.git_org}}/{{cookiecutter.git_repo_pref}}-func-article-dal'
  }
  {
    resourceId: deviceDalId
    repoUrl: 'https://github.com/{{cookiecutter.git_org}}/{{cookiecutter.git_repo_pref}}-func-device-dal'
  }
  {
    resourceId: userLaId
    repoUrl: 'https://github.com/{{cookiecutter.git_org}}/{{cookiecutter.git_repo_pref}}-la-user'
  }
  {
    resourceId: deviceLaId
    repoUrl: 'https://github.com/{{cookiecutter.git_org}}/{{cookiecutter.git_repo_pref}}-la-device'
  }
  {
    resourceId: sharedDeviceLaId
    repoUrl: 'https://github.com/{{cookiecutter.git_org}}/{{cookiecutter.git_repo_pref}}-la-device-shared'
    isSingleEnvironment: true
  }
]
