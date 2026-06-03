extends Resource
class_name EconomyBalancingConfig

@export var starting_coins: int = 1000

# Evolution costs
@export var cost_baby_to_kid: int = 100
@export var cost_kid_to_adult: int = 500
@export var cost_adult_to_elder: int = 1500

# Mini-game reward ranges
@export var reward_easy_min: int = 10
@export var reward_easy_max: int = 20
@export var reward_medium_min: int = 20
@export var reward_medium_max: int = 40
@export var reward_hard_min: int = 40
@export var reward_hard_max: int = 80
@export var reward_expert_min: int = 80
@export var reward_expert_max: int = 150

# Egg prices
@export var price_dino_egg: int = 500
@export var price_slime_egg: int = 500

# Cosmetic price ranges
@export var price_head_min: int = 100
@export var price_head_max: int = 200
@export var price_face_min: int = 50
@export var price_face_max: int = 100
@export var price_body_min: int = 150
@export var price_body_max: int = 300
@export var price_back_min: int = 100
@export var price_back_max: int = 200
