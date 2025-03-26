const rl = @import("raylib");
const another = @import("another.zig");
const std = @import("std");
// const prng = std.Random.DefaultPrng;
// var prng = std.Random.DefaultPrng.init({
//     var seed: u64 = undefined;
//     std.posix.getrandom(std.mem.asBytes(&seed));
// });
// const rand = prng.random();
// const rand: Random = undefined;

const Game = struct {
    projectiles: [100]LaserProjectile,
    projectilesidx: usize,
    rocks: [100]Rock,
    rockidx: usize,

    pub fn init() Game {
        return Game{
            .projectiles = undefined,
            .projectilesidx = 0,
            .rocks = undefined,
            .rockidx = 0,
        };
    }

    pub fn add_projectile(self: *Game, pos: rl.Vector2) void {
        self.projectiles[self.projectilesidx] = LaserProjectile.init(pos, 8, 16);
        self.projectilesidx += 1;
        if (self.projectilesidx >= 100) {
            self.projectilesidx = 0;
        }
    }

    pub fn spawn_rock(self: *Game, rand: std.Random) void {
        const x_rand = rand.intRangeLessThan(u16, 0, screenWidth);
        const spawn_location = rl.Vector2.init(@as(f32, @floatFromInt(x_rand)), 0.0);
        self.rocks[self.rockidx] = Rock.init(spawn_location, 16, 16, rand);
        self.rockidx += 1;
        if (self.rockidx >= 100) {
            self.rockidx = 0;
        }
    }
};
const screenWidth = 800;
const screenHeight = 450;
var game: Game = Game.init();

const Player = struct {
    pos: rl.Vector2,
    direction: rl.Vector2,
    speed: f32,
    radius: f32,

    pub fn init(pos: rl.Vector2) Player {
        return Player{ .pos = pos, .direction = rl.Vector2.init(0.0, 0.0), .speed = 400.0, .radius = 20.0 };
    }

    pub fn update(self: *Player, dt: f32) void {
        self.direction.x = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.d)))) - @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.a))));
        self.direction.y = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.s)))) - @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.w))));
        self.pos.x += self.direction.x * self.speed * dt;
        self.pos.y += self.direction.y * self.speed * dt;
    }

    pub fn draw(self: *Player) void {
        rl.drawCircleV(self.pos, self.radius, rl.Color.black);
    }

    pub fn input(self: Player) void {
        if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
            const initPosition = self.pos;
            game.add_projectile(initPosition);
        }
    }
};

const LaserProjectile = struct {
    pos: rl.Vector2,
    direction: rl.Vector2,
    speed: f32,
    areaRectangle: rl.Rectangle,
    active: bool = false,
    size: rl.Vector2,
    timer: f32,
    proj_lifetime: f32,

    pub fn init(pos: rl.Vector2, width: f32, height: f32) LaserProjectile {
        const laserProj = LaserProjectile{
            .pos = pos,
            .direction = rl.Vector2.init(0.0, -1.0),
            .speed = 500.0,
            .areaRectangle = rl.Rectangle.init(pos.x, pos.y, width, height),
            .size = rl.Vector2.init(width, height),
            .active = true,
            .timer = 0.0,
            .proj_lifetime = 60.0,
        };
        return laserProj;
    }

    pub fn update(self: *LaserProjectile, dt: f32) void {
        if (self.timer >= self.proj_lifetime) {
            self.active = false;
        }
        self.pos.x += self.direction.x * self.speed * dt;
        self.pos.y += self.direction.y * self.speed * dt;
        self.areaRectangle.x = self.pos.x;
        self.areaRectangle.y = self.pos.y;
        self.timer += dt;
    }

    pub fn draw(self: LaserProjectile) void {
        rl.drawRectangleV(self.pos, self.size, rl.Color.red);
    }
};

const Rock = struct {
    pos: rl.Vector2,
    direction: rl.Vector2,
    speed: f32,
    areaRectangle: rl.Rectangle,
    size: rl.Vector2,
    active: bool,
    rotation: f32,

    pub fn init(pos: rl.Vector2, width: f32, height: f32, rand: std.Random) Rock {
        const x_dir = rand.intRangeLessThan(i16, -1, 1);
        return Rock{
            .pos = pos,
            .direction = rl.Vector2.init(@as(f32, @floatFromInt(x_dir)), 1.0),
            .speed = 400.0,
            .areaRectangle = rl.Rectangle.init(pos.x, pos.y, width, height),
            .size = rl.Vector2.init(width, height),
            .active = true,
            .rotation = 0.0,
        };
    }
    pub fn update(self: *Rock, dt: f32) void {
        self.pos.x = self.direction.x * self.speed * dt;
        self.pos.y = self.direction.y * self.speed * dt;
        self.areaRectangle.x = self.pos.x;
        self.areaRectangle.y = self.pos.y;
    }
    pub fn draw(self: Rock) void {
        rl.drawRectangleV(self.pos, self.size, rl.Color.blue);
    }
};

pub fn main() anyerror!void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    // for (0..10) |_| {
    //     std.debug.print("{c}\n", .{@mod(rnd.random().int(u8), 26) + 'a'});
    // }
    const title = "gg";
    another.init2();

    // rl.setConfigFlags(@enumFromInt(@intFromEnum(rl.ConfigFlags.flag_vsync_hint)));
    rl.initWindow(screenWidth, screenHeight, title);
    rl.setExitKey(rl.KeyboardKey.escape);

    rl.setTargetFPS(60);

    const rockSpawnTime = 1.0;
    var rockSpawnTimer: f32 = 0.0;

    var player = Player.init(rl.Vector2.init(300.0, 300.0));

    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();
        rockSpawnTimer += dt;
        if (rockSpawnTimer > rockSpawnTime) {
            game.spawn_rock(rand);
            rockSpawnTimer = 0.0;
        }
        for (&game.projectiles) |*projectile| {
            if (projectile.active) {
                projectile.update(dt);
            }
        }
        for (&game.rocks) |*rock| {
            if (rock.active) {
                rock.update(dt);
            }
        }
        player.update(dt);
        player.input();

        rl.beginDrawing();
        rl.clearBackground(rl.Color.ray_white);
        rl.drawText(title, 190, 200, 20, rl.Color.light_gray);
        for (game.projectiles) |projectile| {
            if (projectile.active) {
                projectile.draw();
            }
        }
        for (&game.rocks) |*rock| {
            if (rock.active) {
                rock.draw();
            }
        }
        player.draw();
        rl.endDrawing();
    }

    rl.closeWindow();
}
