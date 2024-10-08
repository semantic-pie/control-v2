# Control script

This script is used to manage the setup and execution of the project services. It provides commands to install dependencies, build and run services.

## Requirements

- Git
- Docker
- Docker Compose
- Java 17

## Usage

Clone repository:

```bash
git clone git@github.com:semantic-pie/control-v2
````

Create `.env` file:

```bash
cp .env.example .env
```

To make the Snoopy service work, you also need to set variables `SNOOPY_SPOTIFY_CLIENT_ID`, `SNOOPY_SPOTIFY_CLIENT_SECRET` in `.env` manually.

To use the script, run:

```bash
./control.sh help
```

To start, run:

```bash
./control.sh install
# then
./control.sh build
# and
./control.sh run
```

UI runs on `http://localhost:3000`.
