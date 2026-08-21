# Gemini phrase generator (saved for reference / other apps)
# Source: Adele paste, 20 Aug 2026
# Output of a run lives in gemini-365.txt

import random

subjects = [
    "Luck", "Something good", "The day", "A little magic", "Good energy",
    "A quiet kind of luck", "Something brilliant", "The morning", "This moment",
    "A lovely surprise", "Something nice", "A small joy", "A good feeling",
    "Today", "Tomorrow's luck", "A fresh start", "A tiny victory", "A good break",
    "Something beautiful", "A little spark", "The whole day", "A gentle push",
    "A stroke of luck", "A kind word", "A little win", "Something special"
]

verbs = [
    "is on your side", "has your back", "is looking for you", "is heading your way",
    "is in your corner", "wants to say hello", "is waiting for you", "is rooting for you",
    "belongs to you", "is smiling at you", "is ready for you", "is unfolding for you",
    "is meant for you", "is gathering around you", "is finding its way to you",
    "is lining up for you", "is whispering your name", "is working in your favour",
    "is quietly cheering for you", "is wrapping around you", "is taking care of you",
    "is right here for you", "is keeping an eye out for you"
]

suffixes = [
    "today.", "right now.", "this week.", "just for you.", "already.",
    "quietly.", "gently.", "out there.", "in the background.", "somehow.",
    "soon.", "when you need it.", "all day.", "step by step."
]

standalone = [
    "Luck likes you today.", "Make a wish.", "Something has your back.", "On your side.",
    "A little gift, for you.", "You are right on time.", "Everything is lining up.",
    "Breathe easy today.", "It is all going to click.", "Take the win.",
    "You have got this.", "Just for you.", "Keep your eyes peeled for good things.",
    "The wind is at your back.", "Good things are arriving.", "A perfect moment is coming.",
    "You are doing beautifully.", "Expect a lovely surprise.", "Something good is brewing.",
    "You are in the right place.", "A lucky break is due.", "The timing is perfect.",
    "Things are looking up.", "A gentle day ahead.", "You deserve this good luck."
]

phrases = set(standalone)
while len(phrases) < 365:
    if random.random() < 0.3:
        phrase = f"{random.choice(subjects)} {random.choice(verbs)}."
    else:
        phrase = f"{random.choice(subjects)} {random.choice(verbs)} {random.choice(suffixes)}"
    phrase = phrase[0].upper() + phrase[1:]
    if len(phrase.split()) <= 10:
        phrases.add(phrase)

phrases_list = list(phrases)
random.shuffle(phrases_list)

for i in range(365):
    print(f"{i+1}. {phrases_list[i]}")
