# Ruszaj

Ruszaj is a free and open-source public transport app for Poland.

The idea is simple: make it easy to find routes, stops and departures without ads, tracking or unnecessary accounts.

<img width="350" height="750" alt="Screenshot_20260807-004817" src="https://github.com/user-attachments/assets/5db31943-6d37-4e51-8ce4-7bab19a29670" />

## Goals

* Plan public transport routes
* Find nearby stops
* Check departures and delays
* Show walking directions to stops
* Support public transport across Poland
* No ads
* No tracking
* No account required
* Open source

## Privacy

Ruszaj is designed to collect as little data as possible.

Your saved places, favourites and preferences stay on your device. There are no advertising or analytics SDKs used to build a profile of you.

## Self-hosting

Ruszaj comes with a default public server at `ruszaj.mx37.me` so you can try
the app without setting anything up. It proxies requests to Transitous and
doesn't store or log anything about you.

That said, **self-hosting is recommended** if you want full control over
your data path. The backend is a small TypeScript project, so it's genuinely
easy:

```bash
git clone https://github.com/mx37/ruszaj
cd ruszaj/server
npm install
npm start
```

That's it - no API keys, no tokens, no accounts to set up. Just point the app
at your own server URL in Settings.

## Status

Ruszaj is currently in early development.

The app is being built with Flutter and uses open public transport data such as GTFS, GTFS Realtime and OpenStreetMap.

## License

Open source. See the `LICENSE` file for details.
