<!doctype html>
<html lang="en">

<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Reverb Server</title>
    <style>
        :root {
            color-scheme: dark;
        }

        html,
        body {
            height: 100%;
        }

        body {
            margin: 0;
            font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto,
                Helvetica, Arial, "Apple Color Emoji", "Segoe UI Emoji";
            background: radial-gradient(1200px 600px at 50% 10%,
                    rgba(99, 102, 241, 0.18),
                    transparent 60%),
                #0b1020;
            color: #e5e7eb;
            display: grid;
            place-items: center;
        }

        .card {
            width: min(560px, calc(100vw - 48px));
            padding: 28px 26px;
            border-radius: 16px;
            background: rgba(17, 24, 39, 0.72);
            border: 1px solid rgba(255, 255, 255, 0.08);
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.35);
            backdrop-filter: blur(10px);
            text-align: center;
        }

        h1 {
            margin: 0 0 10px;
            font-size: 20px;
            letter-spacing: 0.2px;
        }

        p {
            margin: 0;
            line-height: 1.5;
            color: rgba(229, 231, 235, 0.85);
            font-size: 14px;
        }

        .pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            margin-top: 14px;
            padding: 8px 12px;
            border-radius: 999px;
            background: rgba(99, 102, 241, 0.12);
            border: 1px solid rgba(99, 102, 241, 0.28);
            color: rgba(229, 231, 235, 0.92);
            font-size: 12px;
        }

        .dot {
            width: 8px;
            height: 8px;
            border-radius: 999px;
            background: #22c55e;
            box-shadow: 0 0 0 4px rgba(34, 197, 94, 0.15);
        }

        code {
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas,
                "Liberation Mono", "Courier New", monospace;
            font-size: 12px;
            color: rgba(229, 231, 235, 0.9);
        }
    </style>
</head>

<body>
    <main class="card" role="main" aria-label="Reverb server status">
        <h1>Laravel Reverb is running</h1>
        <p>
            This host is dedicated to WebSocket traffic for realtime broadcasting.
        </p>

        <div class="pill" aria-label="status">
            <span class="dot" aria-hidden="true"></span>
            <span>WebSocket endpoint: <code>wss://reverb.domain.com</code></span>
        </div>
    </main>
</body>

</html>
