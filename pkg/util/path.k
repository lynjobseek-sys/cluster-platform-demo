basename = lambda f: str -> str {
    f.split("/")[-1]
}

path_join = lambda parts: [str] -> str {
    "/".join([p for p in parts if p != ""])
}
