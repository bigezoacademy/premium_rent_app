# Code Citations

## License: unknown
https://github.com/0xSalle/cve-2018-15133/tree/2cbb0d11044bba9b4a195e0b27782a70091c4fd9/main.go

```
= nil {
        return "", err
    }
    defer resp.Body.Close()

    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        return "", err
    }
    return string(body), nil
}

func main() {
```

