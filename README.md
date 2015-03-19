#### Create build instances
```bash
curl -X POST -F repos=cms,carburetor -F build_role=  http://localhost:9292/cleanup/instances
```
#### Clean up old instances
```bash
curl -X POST -F repos=cms -F tag_key='Build Role' -F time=3600  http://localhost:9292/cleanup/instances
```
