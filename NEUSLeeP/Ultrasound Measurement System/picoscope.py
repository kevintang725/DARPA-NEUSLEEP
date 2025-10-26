from picosdk.discover import find_all_units

scopes = find_all_units()

for scope in scopes:
    print(scope.info)
    scope.close()
