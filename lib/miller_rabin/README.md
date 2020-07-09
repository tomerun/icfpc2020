# miller_rabin

Implements [Miller-Rabin](https://en.wikibooks.org/wiki/Algorithm_Implementation/Mathematics/Primality_Testing) algorithm to check if a number is prime

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  miller_rabin:
    github: kuende/miller_rabin
```


## Usage


```crystal
require "miller_rabin"

MillerRabin.probably_prime(10459103, 100)
MillerRabin.probably_prime(5915587219_u64, 100)
```

## Contributing

1. Fork it ( https://github.com/kuende/miller_rabin/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request
