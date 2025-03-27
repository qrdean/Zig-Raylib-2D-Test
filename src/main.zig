const std = @import("std");

const rl = @import("raylib");

const another = @import("another.zig");

const screenHeight = 450;
const screenWidth = 800;
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

const GameData = struct {
    Assets: Assets,
    score: i32,

    pub fn init() anyerror!GameData {
        return GameData{
            .Assets = try Assets.init(),
            .score = 0,
        };
    }
};

const Assets = struct {
    RockTexture: rl.Texture,
    LaserTexture: rl.Texture,
    PlayerTexture: rl.Texture,

    pub fn init() anyerror!Assets {
        return Assets{
            .RockTexture = try rl.loadTexture("assets/meteor.png"),
            .LaserTexture = try rl.loadTexture("assets/laser.png"),
            .PlayerTexture = try rl.loadTexture("assets/spaceship.png"),
        };
    }
};

var game: Game = undefined;
var gameData: GameData = undefined;

const Player = struct {
    pos: rl.Vector2,
    direction: rl.Vector2,
    speed: f32,
    radius: f32,
    texture: rl.Texture,

    pub fn init(pos: rl.Vector2) Player {
        const texture = gameData.Assets.PlayerTexture;
        return Player{
            .pos = pos,
            .direction = rl.Vector2.init(0.0, 0.0),
            .speed = 400.0,
            .radius = 20.0,
            .texture = texture,
        };
    }

    pub fn update(self: *Player, dt: f32) void {
        self.direction.x = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.d)))) - @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.a))));
        self.direction.y = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.s)))) - @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.w))));
        self.pos.x += self.direction.x * self.speed * dt;
        self.pos.y += self.direction.y * self.speed * dt;
    }

    pub fn draw(self: *Player) void {
        // rl.drawCircleV(self.pos, self.radius, rl.Color.black);
        rl.drawTextureV(self.texture, self.pos, rl.Color.white);
    }

    pub fn input(self: Player) void {
        if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
            const offset = 50;
            var initPosition = self.pos;
            initPosition.x += offset;
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
    texture: rl.Texture,

    pub fn init(pos: rl.Vector2, width: f32, height: f32) LaserProjectile {
        const texture = gameData.Assets.LaserTexture;
        const laserProj = LaserProjectile{
            .pos = pos,
            .direction = rl.Vector2.init(0.0, -1.0),
            .speed = 500.0,
            .areaRectangle = rl.Rectangle.init(pos.x, pos.y, width, height),
            .size = rl.Vector2.init(width, height),
            .active = true,
            .timer = 0.0,
            .proj_lifetime = 60.0,
            .texture = texture,
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
        // rl.drawRectangleV(self.pos, self.size, rl.Color.red);
        rl.drawTextureV(self.texture, self.pos, rl.Color.white);
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
    texture: rl.Texture,

    pub fn init(pos: rl.Vector2, width: f32, height: f32, rand: std.Random) Rock {
        const x_dir = rand.intRangeLessThan(i16, -1, 1);
        const texture = gameData.Assets.RockTexture;
        return Rock{
            .pos = pos,
            .direction = rl.Vector2.init(@as(f32, @floatFromInt(x_dir)), 1.0),
            .speed = 250.0,
            .areaRectangle = rl.Rectangle.init(pos.x, pos.y, @as(f32, @floatFromInt(texture.width)), @as(f32, @floatFromInt(texture.height))),
            .size = rl.Vector2.init(width, height),
            .active = true,
            .rotation = 0.0,
            .texture = texture,
        };
    }
    pub fn update(self: *Rock, dt: f32) void {
        self.pos.x += self.direction.x * self.speed * dt;
        self.pos.y += self.direction.y * self.speed * dt;
        self.areaRectangle.x = self.pos.x;
        self.areaRectangle.y = self.pos.y;
    }
    pub fn draw(self: Rock) void {
        rl.drawTextureV(self.texture, self.pos, rl.Color.white);
    }
};

pub fn main() anyerror!void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand: std.Random = prng.random();
    const title = "gg";
    another.init2();

    rl.initWindow(screenWidth, screenHeight, title);
    rl.setExitKey(rl.KeyboardKey.escape);
    game = Game.init();
    gameData = try GameData.init();
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
                for (&game.rocks) |*rock| {
                    if (rock.active) {
                        if (rl.checkCollisionRecs(projectile.areaRectangle, rock.areaRectangle)) {
                            rock.active = false;
                            projectile.active = false;
                            gameData.score += 1;
                        }
                    }
                }
            }
        }

        for (&game.rocks) |*rock| {
            if (rock.active) {
                rock.update(dt);
            }
        }

        player.update(dt);
        player.input();
        var buf: [1024]u8 = undefined;
        const scoreStr = try std.fmt.bufPrintZ(&buf, "{}", .{gameData.score});

        rl.beginDrawing();
        rl.clearBackground(rl.Color.ray_white);
        rl.drawText(title, 190, 200, 20, rl.Color.light_gray);
        rl.drawText(scoreStr, 400, 200, 20, rl.Color.light_gray);
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
