const std = @import("std");
const Allocator = std.mem.Allocator;

const main = @import("root");
const graphics = main.graphics;
const draw = graphics.draw;
const Shader = graphics.Shader;
const TextBuffer = graphics.TextBuffer;
const Texture = graphics.Texture;
const vec = main.vec;
const Vec2f = vec.Vec2f;

const gui = @import("../gui.zig");
const GuiComponent = gui.GuiComponent;
const Label = GuiComponent.Label;

const Button = @This();

const border: f32 = 3;
const fontSize: f32 = 16;

var texture: Texture = undefined;
pub var shader: Shader = undefined;
pub var buttonUniforms: struct {
	screen: c_int,
	start: c_int,
	size: c_int,
	color: c_int,
	scale: c_int,

	image: c_int,
	pressed: c_int,
} = undefined;

pos: Vec2f,
size: Vec2f,
pressed: bool = false,
hovered: bool = false,
onAction: *const fn() void,
label: *Label,

pub fn __init() !void {
	shader = try Shader.initAndGetUniforms("assets/cubyz/shaders/ui/button.vs", "assets/cubyz/shaders/ui/button.fs", &buttonUniforms);
	shader.bind();
	graphics.c.glUniform1i(buttonUniforms.image, 0);
	texture = try Texture.initFromFile("assets/cubyz/ui/button.png");
}

pub fn __deinit() void {
	shader.deinit();
	texture.deinit();
}

fn defaultOnAction() void {}

pub fn init(pos: Vec2f, width: f32, text: []const u8, onAction: ?*const fn() void) Allocator.Error!*Button {
	const label = try Label.init(undefined, width - 3*border, text, .center);
	const self = try gui.allocator.create(Button);
	self.* = Button {
		.pos = pos,
		.size = Vec2f{width, label.size[1] + 3*border},
		.onAction = if(onAction) |a| a else &defaultOnAction,
		.label = label,
	};
	return self;
}

pub fn deinit(self: *const Button) void {
	self.label.deinit();
	gui.allocator.destroy(self);
}

pub fn toComponent(self: *Button) GuiComponent {
	return GuiComponent {
		.button = self
	};
}

pub fn updateHovered(self: *Button, _: Vec2f) void {
	self.hovered = true;
}

pub fn mainButtonPressed(self: *Button, _: Vec2f) void {
	self.pressed = true;
}

pub fn mainButtonReleased(self: *Button, mousePosition: Vec2f) void {
	if(self.pressed) {
		self.pressed = false;
		if(GuiComponent.contains(self.pos, self.size, mousePosition)) {
			self.onAction();
		}
	}
}

pub fn render(self: *Button, mousePosition: Vec2f) !void {
	graphics.c.glActiveTexture(graphics.c.GL_TEXTURE0);
	texture.bind();
	shader.bind();
	graphics.c.glUniform1i(buttonUniforms.pressed, 0);
	if(self.pressed) {
		draw.setColor(0xff000000);
		graphics.c.glUniform1i(buttonUniforms.pressed, 1);
	} else if(GuiComponent.contains(self.pos, self.size, mousePosition) and self.hovered) {
		draw.setColor(0xff000040);
	} else {
		draw.setColor(0xff000000);
	}
	self.hovered = false;
	draw.customShadedRect(buttonUniforms, self.pos, self.size);
	graphics.c.glUniform1i(buttonUniforms.pressed, 0);
	const textPos = self.pos + self.size/@splat(2, @as(f32, 2.0)) - self.label.size/@splat(2, @as(f32, 2.0));
	self.label.pos = textPos;
	try self.label.render(mousePosition - self.pos);
}