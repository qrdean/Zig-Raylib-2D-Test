const rl = @import("raylib");
const another = @import("another.zig");

const Game = struct {
    projectiles: [100]LaserProjectile,
    projectilesidx: usize,

    pub fn init() Game {
        return Game{
            .projectiles = undefined,
            .projectilesidx = 0,
        };
    }

    pub fn add_projectile(self: *Game, pos: rl.Vector2) void {
        self.projectiles[self.projectilesidx] = LaserProjectile.init(pos, 8, 16);
        self.projectilesidx += 1;
        if (self.projectilesidx >= 100) {
            self.projectilesidx = 0;
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
            // initPosition.x += 50;
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

    pub fn init(pos: rl.Vector2, width: f32, height: f32) LaserProjectile {
        const laserProj = LaserProjectile{
            .pos = pos,
            .direction = rl.Vector2.init(0.0, -1.0),
            .speed = 500.0,
            .areaRectangle = rl.Rectangle.init(pos.x, pos.y, width, height),
            .size = rl.Vector2.init(width, height),
            .active = true,
        };
        return laserProj;
    }

    pub fn update(self: *LaserProjectile, dt: f32) void {
        self.pos.x += self.direction.x * self.speed * dt;
        self.pos.y += self.direction.y * self.speed * dt;
        self.areaRectangle.x = self.pos.x;
        self.areaRectangle.y = self.pos.y;
    }

    pub fn draw(self: LaserProjectile) void {
        rl.drawRectangleV(self.pos, self.size, rl.Color.red);
    }
};

const Rock = struct {};

pub fn main() anyerror!void {
    const title = "hey";
    another.init2();

    // rl.setConfigFlags(@enumFromInt(@intFromEnum(rl.ConfigFlags.flag_vsync_hint)));
    rl.initWindow(screenWidth, screenHeight, title);
    rl.setExitKey(rl.KeyboardKey.escape);

    rl.setTargetFPS(60);

    var player = Player.init(rl.Vector2.init(300.0, 300.0));

    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();
        for (&game.projectiles) |*projectile| {
            if (projectile.active) {
                projectile.update(dt);
            }
        }
        player.update(dt);
        player.input();

        rl.beginDrawing();
        rl.clearBackground(rl.Color.ray_white);
        rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);
        for (game.projectiles) |projectile| {
            if (projectile.active) {
                projectile.draw();
            }
        }
        player.draw();
        rl.endDrawing();
    }

    rl.closeWindow();
}
