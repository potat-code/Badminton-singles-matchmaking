class_name GlickoHandler extends Node

const GLICKO_CONSTANT = log(10.0) / 400.0
static func _g(rd: float) -> float:
	# Reduces the impact of opponents with uncertain ratings.
	return 1.0 / sqrt(1.0 + (3.0 * GLICKO_CONSTANT ** 2 * rd ** 2) / (PI * PI))

## The score variables are first to 11~15 (so exactly one is the max). The data dicts contain mmr and rd for each player. 
static func get_gain(first_score: int, second_score: int, first_data: Dictionary, second_data: Dictionary) -> Dictionary:
	var player_rating = first_data.mmr
	var player_rating_deviation = first_data.rd
	var opponent_rating = second_data.mmr
	var opponent_rating_deviation = second_data.rd
	
	var match_result = 1.0 if first_score > second_score else 0.0
	
	# Scale factor based on opponent uncertainty.
	var opponent_scale = _g(opponent_rating_deviation)
	
	# Expected probability that the player wins.
	var expected_score = 1.0 / (
		1.0 + pow(
			10.0,
			-opponent_scale * (player_rating - opponent_rating) / 400.0
		)
	)
	
	# Estimated information gained from this match.
	var rating_variance = 1.0 / (
		GLICKO_CONSTANT ** 2 *
		opponent_scale ** 2 *
		expected_score * (1.0 - expected_score)
	)
	
	# Updated Rating Deviation (RD).
	var new_rating_deviation = sqrt(
		1.0 / (
			1.0 / (player_rating_deviation ** 2) +
			1.0 / rating_variance
		)
	)
	
	# Rating change.
	var rating_change = (
		GLICKO_CONSTANT / (
			1.0 / (player_rating_deviation ** 2) +
			1.0 / rating_variance
		)
	) * opponent_scale * (match_result - expected_score)
	
	player_rating_deviation = new_rating_deviation
	
	return {"mmr": roundi(rating_change), "rd": -new_rating_deviation}
