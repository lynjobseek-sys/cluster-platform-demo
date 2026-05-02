schema Env:
    name: str
    cluster: str

schema App:
    name: str
    chart?: str
    values?: {str:any}

schema Project:
    name: str
    apps: [App] = []

schema Team:
    name: str
    projects: [Project] = []
    envs: [Env] = []
