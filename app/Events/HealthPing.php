<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
// use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class HealthPing implements ShouldBroadcast
{
    use Dispatchable, SerializesModels;

    public string $broadcastQueue = 'broadcasts';

    // which channels it goes to
    public function broadcastOn(): array
    {
        return [new Channel('health')];
    }

    // event name, optional
    public function broadcastAs(): string
    {
        return 'health.ping';
    }

    // payload
    public function broadcastWith(): array
    {
        return ['ok' => true];
    }
}
