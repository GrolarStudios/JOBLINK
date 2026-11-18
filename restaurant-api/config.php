<?php
return [
    'app' => [
        'name' => 'Komanda API',
        'env' => 'production',
        'debug' => false,
        'timezone' => 'America/Mexico_City',
        'base_url' => 'https://grolarstudios.com/restaurant-api/public',
        'allowed_origins' => [
            'https://grolarstudios.com',
            'http://localhost:5000',
            'http://localhost:3000',
        ],
        'token_days' => 30,
        'max_logo_bytes' => 2097152,
    ],
    'database' => [
        'host' => 'localhost',
        'port' => 3306,
        'name' => 'grolars1_bdkomanda',
        'user' => 'grolars1_komanda',
        'password' => 'Grolar2002@',
        'charset' => 'utf8mb4',
    ],
];
