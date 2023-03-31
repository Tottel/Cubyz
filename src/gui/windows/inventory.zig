const std = @import("std");
const Allocator = std.mem.Allocator;

const main = @import("root");
const Player = main.game.Player;
const Vec2f = main.vec.Vec2f;

const gui = @import("../gui.zig");
const GuiComponent = gui.GuiComponent;
const GuiWindow = gui.GuiWindow;
const Button = GuiComponent.Button;
const HorizontalList = GuiComponent.HorizontalList;
const VerticalList = GuiComponent.VerticalList;
const ItemSlot = GuiComponent.ItemSlot;

pub var window = GuiWindow {
	.contentSize = Vec2f{64*8, 64*4},
	.title = "Inventory",
	.id = "cubyz:inventory",
};

const padding: f32 = 8;
pub fn onOpen() Allocator.Error!void {
	var list = try VerticalList.init(.{padding, padding + 16}, 300, 0);
	// Some miscellanious slots and buttons:
	// TODO: armor slots, backpack slot + stack-based backpack inventory, other items maybe?
	{
		var row = try HorizontalList.init();
		try row.add(try Button.init(.{0, 0}, 64, "Crafting", gui.openWindowFunction("cubyz:inventory_crafting"))); // TODO: Replace the text with an icon
		try list.add(row);
	}
	// Inventory:
	for(1..4) |y| {
		var row = try HorizontalList.init();
		for(0..8) |x| {
			try row.add(try ItemSlot.init(.{0, 0}, &Player.inventory__SEND_CHANGES_TO_SERVER.items[y*8 + x])); // TODO: Update server
		}
		try list.add(row);
	}
	list.finish(.center);
	window.rootComponent = list.toComponent();
	window.contentSize = window.rootComponent.?.pos() + window.rootComponent.?.size() + @splat(2, padding);
	gui.updateWindowPositions();
}

pub fn onClose() void {
	if(window.rootComponent) |*comp| {
		comp.deinit();
	}
}