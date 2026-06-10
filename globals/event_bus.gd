extends Node

@warning_ignore("unused_signal")
signal ball_hit_wall(a: Ball)

@warning_ignore("unused_signal")
signal ball_hit_ball(a: Ball, b: Ball)

@warning_ignore("unused_signal")
signal stick_hit_ball(ball: Ball)

@warning_ignore("unused_signal")
signal ball_sunk(ball: Ball)

@warning_ignore("unused_signal")
signal ball_movement_changed(ball: Node, is_moving: bool)
