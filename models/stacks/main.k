import pkg.common.config.managed as managed
import pkg.common.config.teams as teams_cfg
import pkg.gitops.applicationset as gitops_as
import pkg.gitops.appproject as gitops_proj

manifests = [
    gitops_proj.appProject(team, teams_cfg.RepoURL) for team in teams_cfg.Teams
] + [
    gitops_as.simpleOnboarding(p, teams_cfg.RepoURL, teams_cfg.AppPath) for p in managed.ManagedProjects
]
