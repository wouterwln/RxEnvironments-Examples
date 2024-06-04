"""
Actor

The abstract type Actor exists to dispatch on in the update! function of the world. This way we can update the Ball and the Players simulataneously.
"""
abstract type Actor end
