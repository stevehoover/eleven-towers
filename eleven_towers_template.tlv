\m5_TLV_version 1d: tl-x.org
\m5
   / A development template for:
   /
   / /--------------------------------------------------------------------------\
   / | The Second Annual Makerchip ASIC Design Showdown, Summer 2026, Eleven Towers |
   / \--------------------------------------------------------------------------/
   /
   / Each player modifies this template to provide their own custom player
   / control circuitry. This template is for players using TL-Verilog. A Verilog-based
   / template is provided separately. Monitor the Showdown Slack channel for updates.
   / Use the latest template for submission.
   /
   / Just 3 steps:
   /   - Replace all YOUR_GITHUB_ID and YOUR_PLAYER_NAME.
   /   - Code your logic in the module below.
   /   - Submit by the deadline (TBD).
   /
   / Showdown details: https://www.redwoodeda.com/showdown-info and in the repository README.
   /
   /
   / Your circuit should drive the following signals:
   /   /pairing[2:0]
   /      $score[15:0]: Score for each of the 3 possible dice pairings (higher score = better).
   /                    The pairing with the highest score is chosen.
   /      $priority_pair[0:0]: Which pair (0 or 1) gets priority if only one can start building.
   /   $end_turn: Assert to voluntarily end your turn and bank progress.
   /
   / Based on the following inputs (accessible within /_me scope, e.g. /_me$my_turn):
   /   $my_turn: Asserted when it's your turn.
   /   $rolls_this_turn[7:0]: Number of rolls taken this turn (valid when $my_turn).
   /   $num_players[2:0]: Number of players in the game (2-5).
   /   $my_player_index: This player's index (0-4).
   /   $current_player: Index of current player (whose turn it is).
   /   /pairing[2:0] -- 3 possible pairings of the dice
   /      /pair[1:0] -- 2 pairs per pairing
   /         /die[1:0] -- 2 dice per pair
   /            $value[2:0]: Die value (1-6)
   /         $sum[3:0]: Sum of the pair (determines tower)
   /         // Properties of the $sum tower (that this pair would build):
   /         $start_floor[3:0]: Your locked-in floor for this tower at turn start.
   /         $climb_floor[3:0]: Current climb floor for this tower during turn.
   /         $tower_height[3:0]: Goal floor to claim this tower.
   /   /tower[12:2] -- Your tower state (valid when $my_turn)
   /      $tower_height[3:0]: Goal floor to claim this tower.
   /      $turn_start_floor[3:0]: Your locked-in floor when turn started.
   /      $climb_floor[3:0]: Current floor during this turn (before ending turn).
   /      $climbing: Whether you've begun climbing this tower this turn.
   /      $claimed: Has any player claimed this tower? (blocks further building)
   /   $climbing_cnt[1:0]: Number of towers you're climbing this turn (max 3).
   /   $claimed_cnt[2:0]: Number of towers you've claimed so far.
   / And from the /_top scope (e.g. /_top/player[#player]/tower[2]$floor):
   /   /player[m5_PLAYER_MAX:0] -- All players' state ([#player] is yourself)
   /      /tower[12:2] -- Each tower's state for this player
   /         $max[3:0]: Max floor of this tower (same for all players).
   /         $floor[3:0]: Locked-in floor for this player.
   /         $claimed: Whether this player has claimed this tower.
   /
   / See also the game parameters and interface documentation in `eleven_towers_lib.tlv`.

   use(m5-1.0)


// Modify this TL-Verilog macro to implement your control circuitry.
// Replace YOUR_GITHUB_ID with your GitHub ID, excluding non-word characters (alphabetic, numeric,
// and "_" only)
// Args (these are text substituted):
//   /_top: The top-level game scope, which contains the entire game state.
//   /_me: This player logic scope (the scope of the /TLV team_* macro)
//   #player: This player's index (0, 1, ...)
// See example opponent logic in `eleven_towers_lib.tlv` for reference.
\TLV team_YOUR_GITHUB_ID(/_top, /_me, #player)
   
   //-----------------------\
   //  Your Code Goes Here  |
   //-----------------------/
   
   // Example: Score each pairing randomly and end turn after 5 rolls
   /pairing[2:0]
      // Assign a score to each pairing (higher = better)
      $score[15:0] = 16'd0;  // Replace with your scoring logic
      
      // Which pair gets priority when only one can build
      $priority_pair[0:0] = 1'b0;
   
   // Decide whether to end the turn
   $end_turn = 1'b1;  // Replace with your strategy
   
   
   // [Optional]
   // Custom visualization for debugging (appears to the right of game board)
   \viz_js
      box: {width: 100, height: 100, strokeWidth: 1},
      where: {left: 50, top: 0, width: 40, height: 100},
      render() {
         // IMPORTANT! Show only during your turn (play nice with other players)
         m5_player_color(#player)
         let o = this.getObjects()
         o.box.set({stroke: player_color})
         o.box.group.set({opacity: '$my_turn'.asBool() ? 1 : 0})
         
         // Access your signals for visualization
         let rolls = '$rolls_this_turn'.asInt();
         
         // Return fabric.js objects to display
         return [
            new fabric.Rect({
               left: 0, top: 0, width: 100, height: 100,
               fill: "#f0f0f0", strokeWidth: 0
            }),
            new fabric.Text("My Strategy", {
               left: 50, top: 30, originX: "center",
               fontSize: 7, fontFamily: "Roboto", fontWeight: "bold"
            }),
            new fabric.Text(`Roll ${rolls}`, {
               left: 50, top: 50, originX: "center",
               fontSize: 6, fontFamily: "Roboto"
            })
         ];
      }



// Compete!
// This defines the competition to simulate (for development).
// When this file is included as a library (for competition), this code is ignored.
\SV
   // Include the Eleven Towers framework.
   ///m4_include_lib(https://raw.githubusercontent.com/rweda/eleven-towers/main/eleven_towers.tlv)
   
   m5_makerchip_module
\TLV
   // Enlist players for the game.
   
   // Your player. Provide:
   //   - your GitHub ID (as in your \TLV team_* macro, above)
   //   - your player name--anything you like (that isn't crude or disrespectful)
   m5_define_player(YOUR_GITHUB_ID, YOUR_PLAYER_NAME)
   
   // Choose your opponent(s) (up to you + 4 opponents).
   // "random" and "seven" are example opponents defined in eleven_towers_lib.tlv.
   // Note that inactive players must be commented with "///", not "//", to prevent M5 macro evaluation.
   ///m5_define_player(random, Random Player)
   m5_define_player(seven, Seven Strategy)
   
   // Instantiate the Eleven Towers game.
   m5+eleven_towers_game(/top)
\SV
   endmodule
