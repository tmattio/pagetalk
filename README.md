# PageTalk

PageTalk is a lightweight, self-hosted commenting system for static websites and blogs. It provides a simple JavaScript client that can be embedded in any webpage and a moderation dashboard for managing comments.

## Development

1. Install Dune:
```bash
curl -fsSL https://get.dune.build/install | sh
```

2. Clone the repository:
```bash
git clone https://github.com/tmattio/pagetalk.git
cd pagetalk
```

3. Build the project:
```bash
dune pkg lock && dune build
```

4. Run the server:
```bash
dune exec pagetalk
```

## Contributing

Contributions are welcome! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

ISC License. See [LICENSE](LICENSE) for details.
