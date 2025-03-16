\m5_TLV_version 1d --inlineGen: tl-x.org
\m5
   / A library for Makerchip that provides a game with gameplay similar to the
   / Connect 4 game from Hasbro.
   
   use(m5-1.0)
   / Player IDs should be defined by each player's library file using
   / var(player_id, xxx)
   / thus defining a stack of player_ids.
   
   var(player0_color, "#d01010")
   var(player1_color, "#d0d010")
   var(die_size, 7.2)
   var(die_stroke_width, 0)
   var(pip_radius, 0.78)
   
   / Push up to two random players if player_id's are not already defined.
   repeat(2, [
      if(m5_depth_of(player_id) < 2, [
         var(player_id, random)
      ])
   ])
   
// Player logic providing random choice.
// The highest score is chosen.
// Input:
//   /pairing[2:0]         // 3 possible pairings of the dice
//      /pair[1:0]            // 2 pairs of dice (for each pairing)
//         /die[1:0]             // Two dice per pair
//            $value[2:0]           // Value of die
//         $sum[3:0]             // Sum of die pair
//         // Properties of the $sum towers (that this pair would build):
//         $my_height[3:0]       // Height of my tower
//         $turn_height[3:0]     // Active height of my tower during the turn
//         $opponent_height[3:0] // Height of opponent's tower 
//         $max_height[3:0]      // Max height of towers
// Output:
//   /pairing[2:0]
//      $score[?:0] = ...;
//      $priority_pair[0:0] = ...;   // The pair of dice that gets priority if
//                                   // either, but not both, can start building,
//                                   // if this pairing is chosen.
//   $end_turn = ...;
\TLV player_random(/_top)
   /pairing[2:0]
      m4_rand($rand, 31, 0, pairing)
      $score[7:0] = $rand % 256;
      $priority_pair[0:0] = 1'b0;
   m4_rand($end_turn, 0, 0)

// Logic shared by /top/player0 and /top/player0
\TLV player()
   /pairing[2:0]
      //$ANY = /top/pairing$ANY;
      /pair[1:0]
         $ANY = /top/pairing/pair$ANY;
         /die[1:0]
            $ANY = /top/pairing/pair/die$ANY;
            `BOGUS_USE($value)
      /* verilator lint_save */
      /* verilator lint_off width */
      $score16[15:0] = $score;
      /* verilator lint_restore */


\TLV eleven_towers_game()
   // Reset, delayed by one cycle, so we have an empty board on cycle 0.
   $real_reset = *reset;
   $reset = >>1$real_reset;
   
   \SV_plus
      logic[3:0] *max[12:2] = {4'd2, 4'd4, 4'd6, 4'd8, 4'd10, 4'd12, 4'd10, 4'd8, 4'd6, 4'd4, 4'd2};
   
   
   
   // -------------------------
   // Game State
   
   // Which player's turn is it?
   $Player <= $reset                  ? 1'b0 :
              /active_player$end_turn ? ! $Player :
              /active_player$bust     ? ! $Player :
                                        $RETAIN;
   
   /player[1:0]
      /tower[12:2]
         $max[3:0] = *max\[#tower\];
         $max_height[3:0] = *max\[#tower\] + 1;
         $Height[3:0] <=
              /top$reset                 ? 4'b0 :
              ! /top/active_player$end_turn || /top/active_player$bust
                                         ? $RETAIN :
              // successful end-of-turn
              /top$Player == #player     // for me
                                         ? /top/active_player/tower$my_next_turn_height :
              // for my opponent
              /top/active_player/tower$my_next_turn_height >= $max_height
                                         // and this tower is complete for them
                                         ? 4'b0 :
              // and they did not complete this tower
                                           $RETAIN;
         // Reached the max (claimed the tower).
         $maxed = $Height == $max_height;
         
         \viz_js
            box: {left: -7, width: 14, height: 170, strokeWidth: 0},
            init() {
               this.tower_heights = [2, 4, 6, 8, 10, 12, 10, 8, 6, 4, 2]
               this.top = function (pos) {
                  return 7 + 12 * (12 - pos)
               }
               let ret = {}
               // Towers.
               let height = this.tower_heights[this.getIndex() - 2]
               let player = this.getIndex("player")
               for(let i = 0; i <= height; i++) {
                  ret[i] =
                       new fabric.Rect({left: 0, top: this.top(i), originX: "center", originY: "center",
                                        width: 10, height: 10,
                                        fill: player ? "transparent" : "#707070", strokeWidth: 0,
                                      })
               }
               // Tower numbers.
               if (player == 0) {
                  let props = {left: 0, originX: "center", originY: "center", fill: "white", fontSize: 6, fontFamily: "Roboto"}
                  let index_str = this.getIndex().toString()
                  ret.tower_num_bottom = new fabric.Text(index_str, {top: this.top(-1), ...props})
                  ret.tower_num_top = new fabric.Text(index_str, {top: this.top(height), ...props})
                  this.tower_num_top_set = false
               }
               return ret
            },
            render() {
               let objs = this.getObjects()
               let player = this.getIndex("player")
               let color = player ? m5_player1_color : m5_player0_color
               for(let i = 0; i <= '$max'.asInt(); i++) {
                  objs[i].set({fill: i >= '$Height'.asInt()
                                        ? ('/top$Player'.asInt() == player && i < '/top/active_player/tower[this.getIndex("tower")]$my_next_turn_height'.asInt()
                                              ? "white" :
                                           //default
                                                (player ? "transparent" : (i == '$max'.asInt() ? "#303030" : "#707070"))
                                          ) :
                                        // default
                                          color})
               }
               if (player == 0) {
                  objs.tower_num_top.set({fill: '$Height'.asInt() > '$max'.asInt() ? "transparent" : "white"})
               }
            },
            where: {left: -30, top: 17, width: 60, height: 56, justifyX: "center", justifyY: "top"},
      \viz_js
         layout: {left: 0.9, top: -0.7},
   
   // -------------------------
   // Dice
   
   // Four rolled dice values.
   /die[3:0]
      $value[2:0] = $random[31:0] % 6 + 1;
      \viz_js
         box: {width: 10, height: 10},
         render() {
            let top_context = this.getScope("top").context
            let player_color = '/top$Player'.asBool() ? m5_player1_color : m5_player0_color
            let pip_color = this.getIndex("die") == 0 || '/top/active_player/pairing[(this.getIndex("die") + 2) % 3]$chosen'.asBool() ? "white" : "black"
            return [top_context.die(player_color, pip_color, '$value'.asInt(), 5, 5, 1)]
         },
         where: {left: -12.5, top: 73, width: 25, height: 10, justifyX: "center", justifyY: "bottom"}
   
   // Possible die pairings:
   //   Pair: 0       1
   //   Die:0  1    0  1
   //   0: [0, 1], [2, 3]
   //   1: [0, 2], [1, 3]
   //   2: [0, 3], [1, 2]
   /pairing[2:0]
      /pair[1:0]
         $sum[3:0] = /die[0]$value + /die[1]$value;
         // Locked-in height.
         $my_height[3:0] = /top/player[/top$Player]/tower[$sum]$Height;
         // Height for this turn.
         $turn_height[3:0] = /top/active_player/tower[$sum]$TurnHeight;
         $opponent_height[3:0] = /top/player[~ /top$Player]/tower[$sum]$Height;
         $max_height[3:0] = *max\[$sum\] + 1;
         // These may or may not be used by the players.
         `BOGUS_USE($my_height $turn_height $opponent_height $max_height)
         /die[1:0]
            $value[2:0] = /top/die[
                 #pair == 0 ? #pairing * #die + #die \:
                 #die == 0  ? (#pairing == 0 ? 2 \: 1) \:
                              (#pairing == 2 ? 2 \: 3)
               ]$value;

   \viz_js
      box: {left: -50, top: 0, width: 100, height: 100, fill: "gray", strokeWidth: 0},
      init() {
         // Create a die.
         this.die = function (die_color, pip_color, value, left, top, scale) {
            pip = function (left, top) {
               return new fabric.Circle(
                  {left, top, radius: m5_pip_radius,
                   fill: pip_color, strokeWidth: 0, originX: "center", originY: "center"
                  }
               )
            }
            let die = new fabric.Group(
               [new fabric.Rect(
                  {width: m5_die_size + m5_die_stroke_width, height: m5_die_size + m5_die_stroke_width,
                   rx: 0.8, ry: 0.8,
                   originX: "center", originY: "center",
                   fill: die_color, strokeWidth: m5_die_stroke_width, stroke: "gray",
                  }
                )
               ],
               {left, top, scaleX: scale, scaleY: scale, originX: "center", originY: "center"}
            )
            if (value % 2) {
               // Add center pip.
               die.add(pip(0, 0))
            }
            let edge_delta = 2
            if (value > 1) {
               die.add(pip(edge_delta, -edge_delta))
               die.add(pip(-edge_delta, edge_delta))
            }
            if (value > 3) {
               die.add(pip(edge_delta, edge_delta))
               die.add(pip(-edge_delta, -edge_delta))
            }
            if (value == 6) {
               die.add(pip(-edge_delta, 0))
               die.add(pip(edge_delta, 0))
            }
            die.addWithUpdate()
            return die
         }
         
         return {}
      },
   /player0
      m5+player()
      m5+call(['player_']m5_get_ago(player_id, 0), /player0)
   /player1
      m5+player()
      m5+call(['player_']m5_get_ago(player_id, 1), /player1)
   /active_player
      $ANY = /top$Player ? /top/player1$ANY : /top/player0$ANY;
      /pairing[2:0]
         \viz_js
            box: {left: -26, top: -7, width: 52, height: 14, strokeWidth: 0, rx: 3, ry: 3},
            layout: {left: 0, top: 15},
            renderFill() {
               return '$chosen'.asBool() ? "#A0A0D0" : "transparent"
            },
            render() {
               return [new fabric.Text('$score16'.asInt().toString(), {
                                       left: -27, top: 0, originX: "right", originY: "center",
                                       fontSize: 7, fontFamily: "Roboto", fill: "black"})]
            },
            where: {left: -8, top: 86, width: 16, height: 10, justifyX: "center", justifyY: "bottom"},
         $ANY = /top$Player ? /top/player1/pairing$ANY : /top/player0/pairing$ANY;
         `BOGUS_USE($score16 $priority_pair)
         // Compare with next, giving priority
         $better_than_next = $score16 >  /pairing[(#pairing + 1) % 3]$score16;
         $equal_to_next    = $score16 == /pairing[(#pairing + 1) % 3]$score16;
         // Choice, prioritizing 0.
         $chosen =
            #pairing == 0 ? (/pairing[0]$better_than_next ||
                             /pairing[0]$equal_to_next) &&
                            ! /pairing[2]$better_than_next :
            #pairing == 1 ? ! /pairing[0]$chosen &&
                            (/pairing[1]$better_than_next ||
                             /pairing[1]$equal_to_next) :
                            ! /pairing[0]$chosen &&
                            ! /pairing[1]$chosen;
         /pair[1:0]
            \viz_js
               box: {strokeWidth: 0},
               layout: {left: 25, top: 0},
               where: {left: -22.5, top: -5, width: 45, height: 10},
            $ANY = /top$Player ? /top/player1/pairing/pair$ANY : /top/player0/pairing/pair$ANY;
            `BOGUS_USE($sum)
            /die[1:0]
               $ANY = /top$Player ? /top/player1/pairing/pair/die$ANY : /top/player0/pairing/pair/die$ANY;
               \viz_js
                  box: {width: 10, height: 10, strokeWidth: 0},
                  layout: "horizontal",
                  render() {
                     let top_context = this.getScope("top").context
                     let player_color = '/top$Player'.asBool() ? m5_player1_color : m5_player0_color
                     let pip_color = this.getIndex("pair") ? "black" : "white"
                     return [top_context.die(player_color, pip_color, '$value'.asInt(), 5, 5, 1)]
                  },
      $chosen_pairing[1:0] = /active_player/pairing[0]$chosen ? 2'd0 :
                             /active_player/pairing[1]$chosen ? 2'd1 :
                                                                2'd2;
      /chosen_pair[1:0]
         $ANY = /active_player/pairing[/active_player$chosen_pairing]/pair[#chosen_pair]$ANY;
         `BOGUS_USE($sum)
      // The number of towers being actively built (up to 3).
      $NumBuilding[1:0] <= /top$reset ? 4'd0 : 4'd0;
      `BOGUS_USE($NumBuilding)
      /tower[12:2]
         //$ANY = /top/player[/top$Player]/tower[#tower]$ANY;
         $max_height[3:0] = *max\[#tower\] + 1;
         // Blocked if opponent is at max.
         /other_players_tower
            $ANY = /top/player[! /top$Player]/tower$ANY;
         $blocked = /other_players_tower$maxed;
         // Update height, incrementing +1 for each matching pair,
         // then capping at max and switching on end turn.
         $delta[3:0] = {3'b0, /active_player/chosen_pair[0]$sum == #tower} +
                       {3'b0, /active_player/chosen_pair[1]$sum == #tower};
         $height_plus_delta[3:0] = $TurnHeight + $delta;
         $my_next_turn_height[3:0] =
              $blocked
                   ? 4'b0 :
              $height_plus_delta >= $max_height
                   ? $max_height :
                     $height_plus_delta;
         $height_change = $my_next_turn_height != $TurnHeight;
         $TurnHeight[3:0] <=
              /top$reset              ? 4'b0 :
              // If end turn, set height for next player.
              /active_player$turn_over ? /top/player[! /top$Player]/tower$Height :
                                         $my_next_turn_height;
      
      // Bust if no tower heights change.
      $bust = ! | /tower[*]$height_change;
      $turn_over = $end_turn || $bust;
   
      \viz_js
         box: {},
         template: {
            action: [
               "Text", "", {
                  left: 18, top: 72,
                  fontSize: 8, fontFamily: "Roboto", fill: "black"
               }
            ]
         },
         render() {
            debugger
            this.getObjects().action.set('$bust'.asBool()
                                            ? {text: "✖", fill: "red"} :
                                         '$end_turn'.asBool()
                                            ? {text: "✓", fill: "green"} :
                                         //default
                                              {text: "…", fill: "#101010"})
         },
         where: {}
   
   // --------------------
   // VIZ-Only
   
   $win = 1'b0;
   /header_player[1:0]
      \viz_js
         box: {width: 100, height: 15, fill: "#a0e0a0"},
         init() {
            return {
               circle: new fabric.Circle({
                    left: 4.5, top: 2.5,
                    radius: 5, strokeWidth: 1,
                    fill: "gray",
                    stroke: "#00000080"}),
               id: new fabric.Text("-", {
                    left: 17, top: 4,
                    fontSize: 7, fontFamily: "Roboto", fill: "black"
               }),
            }
         },
         render() {
            // Can't do this in init() because this.getIndex isn't currently available.
            let o = this.getObjects()
            let i = this.getIndex()
            o.circle.set({fill: i ? m5_player1_color : m5_player0_color,
                          stroke: '/top$win'.asBool() && ('/top>>1$Player'.asInt() == this.getIndex()) ? "cyan" : "gray"})
            o.id.set({text: this.getIndex() ? "m5_get_ago(player_id, 1)" : "m5_player_id"})
         },
         where: {left: -25, top: 3, width: 50, height: 8, justifyX: "center", justifyY: "bottom"},
   
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 80;
   *failed = 1'b0;
\SV
   m5_makerchip_module
\TLV
   m5+eleven_towers_game()
\SV
   endmodule
