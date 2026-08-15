//
//  InspirationData.swift
//  WhiteRabbits
//
//  Twelve months of gentle, secular lines and prompts. One family per
//  month, picked by the day of the month so it changes slowly.
//

import Foundation

struct InspirationLine {
    let line: String
    let prompt: String
}

enum InspirationData {
    static let byMonth: [[InspirationLine]] = [
        // January
        [
            InspirationLine(line: "The year is still frost and possibility.", prompt: "What wants a slow beginning?"),
            InspirationLine(line: "Even the shortest days keep a pale gold.", prompt: "Where is the light arriving first?"),
            InspirationLine(line: "Quiet is a kind of weather too.", prompt: "What can stay unhurried this morning?"),
        ],
        // February
        [
            InspirationLine(line: "Under the soil, something is already reaching.", prompt: "What is stirring, even if you cannot see it?"),
            InspirationLine(line: "Tenderness is a form of attention.", prompt: "Who or what could use a gentler look?"),
            InspirationLine(line: "Early colour returns before we are ready.", prompt: "What small colour did you notice?"),
        ],
        // March
        [
            InspirationLine(line: "Light and dark share the hours as equals.", prompt: "Where do you need a little more balance?"),
            InspirationLine(line: "The first green is a quiet courage.", prompt: "What is just beginning to show?"),
            InspirationLine(line: "Wind moves the old leaves so the new can breathe.", prompt: "What can you let loosen today?"),
        ],
        // April
        [
            InspirationLine(line: "Rain is how the ground drinks.", prompt: "What is feeding you quietly?"),
            InspirationLine(line: "Growth prefers weather to willpower.", prompt: "Where can you stop forcing and start allowing?"),
            InspirationLine(line: "Seeds do not apologise for taking time.", prompt: "What are you willing to tend without rushing?"),
        ],
        // May
        [
            InspirationLine(line: "Blossom is brief, and that is part of its honesty.", prompt: "What is open in you right now?"),
            InspirationLine(line: "The air has learned a softer temperature.", prompt: "How does the morning feel on your skin?"),
            InspirationLine(line: "May is an invitation, not a demand.", prompt: "What would you say yes to, lightly?"),
        ],
        // June
        [
            InspirationLine(line: "The longest light asks only that you notice it.", prompt: "Where will you stand in the sun today?"),
            InspirationLine(line: "Warmth is a kind of luck we can share.", prompt: "Who could use a little of your warmth?"),
            InspirationLine(line: "Midsummer does not hurry, and neither must you.", prompt: "What can take the whole day?"),
        ],
        // July
        [
            InspirationLine(line: "Heat teaches the body to move more slowly.", prompt: "Where can you choose ease over effort?"),
            InspirationLine(line: "Ripe things ask to be enjoyed, not earned.", prompt: "What is already enough this morning?"),
            InspirationLine(line: "The day is full. You do not have to be.", prompt: "What can stay simple?"),
        ],
        // August
        [
            InspirationLine(line: "Golden hour lives in ordinary rooms too.", prompt: "What is catching the light this morning?"),
            InspirationLine(line: "Harvest begins with noticing what has grown.", prompt: "What have you already gathered this year?"),
            InspirationLine(line: "August keeps the warmth and hints at turning.", prompt: "What are you ready to carry forward?"),
        ],
        // September
        [
            InspirationLine(line: "The first cool morning is a kindness.", prompt: "What feels clearer in this air?"),
            InspirationLine(line: "Leaves turn without being told it is time.", prompt: "What change can you meet without argument?"),
            InspirationLine(line: "September is a long exhale.", prompt: "What can you set down?"),
        ],
        // October
        [
            InspirationLine(line: "Dusk arrives earlier, and the room grows intimate.", prompt: "What do you want closer this month?"),
            InspirationLine(line: "Fallen leaves are not a failure of the tree.", prompt: "What ending can you treat as natural?"),
            InspirationLine(line: "October asks for gathering in, not giving up.", prompt: "What is worth keeping near?"),
        ],
        // November
        [
            InspirationLine(line: "Embers are the fire, practising rest.", prompt: "What warmth remains if you stop pushing?"),
            InspirationLine(line: "The low sun still knows your face.", prompt: "Where will you put yourself in the light?"),
            InspirationLine(line: "November is a hearth month.", prompt: "What would make today feel like coming home?"),
        ],
        // December
        [
            InspirationLine(line: "The longest night still contains a small light.", prompt: "What tiny light are you keeping?"),
            InspirationLine(line: "Stars do not compete. They simply appear.", prompt: "Where can you stop comparing and just be?"),
            InspirationLine(line: "A year ends the way a day does: with permission to begin again.", prompt: "What do you want to carry into the next morning?"),
        ],
    ]

    static func today(for date: Date = Date()) -> InspirationLine {
        let calendar = Calendar.current
        let monthIndex = max(0, calendar.component(.month, from: date) - 1)
        let day = calendar.component(.day, from: date)
        let pool = byMonth[monthIndex]
        return pool[(day - 1) % pool.count]
    }
}
