// Debugger test program. See test/debug/README.md.
struct Player {
    name: &'static str,
    score: i32,
}

fn total(players: &[Player]) -> i32 {
    let mut sum = 0;
    for (i, player) in players.iter().enumerate() {
        let _ = (i, player.name);
        sum += player.score; // BREAK: step here, watch `sum`, try `i == 2`
    }
    sum
}

fn main() {
    let players = vec![
        Player { name: "ada", score: 3 },
        Player { name: "bob", score: 5 },
        Player { name: "cy", score: 8 },
        Player { name: "dee", score: 13 },
    ];
    let args: Vec<String> = std::env::args().skip(1).collect();
    println!("args: {:?}", args);
    println!("total: {}", total(&players));
}
