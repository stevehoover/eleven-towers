\m5_TLV_version 1d --inlineGen: tl-x.org
\m5
   / A library for Makerchip that provides a game with gameplay similar to the
   / Connect 4 game from Hasbro.
   
   use(m5-1.0)
   / Player IDs should be defined by each player's library file using
   / var(player_id, xxx)
   / thus defining a stack of player_ids.
   
   define_hier(PLAYER, 5)
   
   var(die_size, 7.2)
   var(die_stroke_width, 0)
   var(pip_radius, 0.78)
   
   / Macro to get player color from render().
   / $1: Player index
   macro(player_color, ['let player_color = this.getScope("top").context.player_color[$1]'])
   
   / Push random players if player_id's are not already defined.
   repeat(m5_PLAYER_CNT, [
      if(m5_depth_of(player_id) < m5_PLAYER_CNT, [
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
   $reset = *reset;
   
   \SV_plus
      logic[3:0] *max[12:2] = {4'd2, 4'd4, 4'd6, 4'd8, 4'd10, 4'd12, 4'd10, 4'd8, 4'd6, 4'd4, 4'd2};
   
   
   
   // -------------------------
   // Game State
   
   // Which player's turn is it?
   $next_player[m5_PLAYER_RANGE] =
        $Player == m5_PLAYER_MAX ? m5_PLAYER_INDEX_HIGH'd0 :
                                   $Player + m5_PLAYER_INDEX_HIGH'd1;
   $Player[m5_PLAYER_RANGE] <=
        $reset                   ? 1'b0 :
        /active_player$turn_over ? $next_player :
                                   $RETAIN;
   
   /m5_PLAYER_HIER
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
               m5_player_color(player)
               for(let i = 0; i <= '$max'.asInt(); i++) {
                  objs[i].set({fill: i >= '$Height'.asInt()
                                        ? ('/top$Player'.asInt() == player && i < '/top/active_player/tower[this.getIndex("tower")]$my_next_turn_height'.asInt()
                                              ? "white" :
                                           //default
                                                (player > 0 ? "transparent" : (i == '$max'.asInt() ? "#303030" : "#707070"))
                                          ) :
                                        // default
                                          player_color})
               }
               if (player == 0) {
                  objs.tower_num_top.set({fill: '$Height'.asInt() > '$max'.asInt() ? "transparent" : "white"})
               }
            },
            where: {left: -30, top: 17, width: 60, height: 56, justifyX: "center", justifyY: "top"},
      \viz_js
         box: {strokeWidth: 0},
         layout: {left: 0.9, top: -0.7},
   
   // -------------------------
   // Dice
   
   // Four rolled dice values.
   /die[3:0]
      $value[2:0] = $random[31:0] % 6 + 1;
      \viz_js
         box: {width: 10, height: 10, strokeWidth: 0},
         render() {
            let top_context = this.getScope("top").context
            let pip_color = this.getIndex("die") == 0 || '/top/active_player/pairing[(this.getIndex("die") + 2) % 3]$chosen'.asBool() ? "white" : "black"
            return [top_context.die('/top$Player'.asInt(), pip_color, '$value'.asInt(), 5, 5, 1)]
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
         // Not for > 2 players
         //$opponent_height[3:0] = /top/player[~ /top$Player]/tower[$sum]$Height;
         $max_height[3:0] = *max\[$sum\] + 1;
         // These may or may not be used by the players.
         `BOGUS_USE($my_height $turn_height /*$opponent_height*/ $max_height)
         /die[1:0]
            $value[2:0] = /top/die[
                 #pair == 0 ? #pairing * #die + #die \:
                 #die == 0  ? (#pairing == 0 ? 2 \: 1) \:
                              (#pairing == 2 ? 2 \: 3)
               ]$value;

   \viz_js
      box: {left: -50, top: 0, width: 100, height: 100, fill: "#40a070", strokeWidth: 0},
      init() {
         // Player colors.
         this.player_color = ["#d01010", "#d0d010", "#109010", "#1010d0", "#d06010"]
         
         // Create a die.
         this.die = (player, pip_color, value, left, top, scale) => {
            debugger
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
                   fill: this.player_color[player], strokeWidth: m5_die_stroke_width, stroke: "gray",
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
                     let pip_color = this.getIndex("pair") ? "black" : "white"
                     return [top_context.die('/top$Player'.asInt(), pip_color, '$value'.asInt(), 5, 5, 1)]
                  },
      $chosen_pairing[1:0] = /active_player/pairing[0]$chosen ? 2'd0 :
                             /active_player/pairing[1]$chosen ? 2'd1 :
                                                                2'd2;
      /chosen_pairing
         $ANY = /active_player/pairing[/active_player$chosen_pairing]$ANY;
         /pair[1:0]
            $ANY = /active_player/pairing[/active_player$chosen_pairing]/pair$ANY;
            `BOGUS_USE($sum)
      /tower[12:2]
         //$ANY = /top/player[/top$Player]/tower[#tower]$ANY;
         $max_height[3:0] = *max\[#tower\] + 1;
         // Blocked if any player is at max.
         // Specifically for 2-player.
         ///other_players_tower
         //   $ANY = /top/player[! /top$Player]/tower$ANY;
         // Determine whether this tower is blocked (any player is maxed).
         /m5_PLAYER_HIER
            $maxed = /top/player/tower$maxed;
         $blocked = | /player[*]$maxed;
         //-$blocked = /other_players_tower$maxed;
         // Update height, incrementing +1 for each matching pair,
         // then capping at max and switching on end turn.
         /chosen_pair[1:0]
            $matches = /active_player/chosen_pairing/pair[#chosen_pair]$sum == #tower;
            $delta[3:0] = {3'b0, $matches};
            $priority = /active_player/chosen_pairing$priority_pair == #chosen_pair;
            // This is a priority pair that claims a new tower.
            $new_priority_tower =   $priority && $matches && ! /tower$blocked && ! /tower$active && /active_player$active_tower_cnt                  != 2'd3;
            // This pair causes this tower to grow.
            $grow = $matches && ! /tower$blocked &&
                    (/tower$active || $new_priority_tower || /active_player$active_tower_cnt_for_low_priority != 2'd3);
         $new_priority_tower = | /chosen_pair[*]$new_priority_tower;
         $grow = | /chosen_pair[*]$grow;   // Either pair causes this tower to grow.
         $delta[3:0] = /chosen_pair[0]$delta +
                       /chosen_pair[1]$delta;
         $height_plus_delta[3:0] = $TurnHeight + $delta;
         $my_next_turn_height[3:0] =
              //$blocked
              //     ? 4'b0 :
              ! $grow
                   ? $TurnHeight :
              $height_plus_delta >= $max_height
                   ? $max_height :
                     $height_plus_delta;
         $turn_maxed = $my_next_turn_height == $max_height;
         //$height_change = $my_next_turn_height != $TurnHeight;
         $TurnHeight[3:0] <=
              /top$reset              ? 4'b0 :
              // If end turn, set height for next player.
              /active_player$turn_over ? /top/player[(/top$Player + m5_PLAYER_INDEX_HIGH'd1) % m5_PLAYER_CNT]/tower<<1$Height :
                                         $my_next_turn_height;
         $active = $TurnHeight != /top/player[/top$Player]/tower$Height;
         // number of towers being actively built (max of 3) and at max for this player (max of 4), accumulate from tower 2 upward
         $active_tower_cnt_accum[1:0] =
              {1'b0, $active} +
              (#tower == 2 ? 2'b0 : /tower[#tower == 2 ? 12 \: #tower - 1]$active_tower_cnt_accum);
         $maxed_tower_cnt_accum[2:0] =
              {2'b0, $turn_maxed} +
              (#tower == 2 ? 3'b0 : /tower[#tower == 2 ? 12 \: #tower - 1]$maxed_tower_cnt_accum);
      $active_tower_cnt[1:0] = /tower[12]$active_tower_cnt_accum;
      $maxed_tower_cnt[2:0] = /tower[12]$maxed_tower_cnt_accum;
      $new_priority_tower = | /tower[*]$new_priority_tower;
      // Active tower count including the current high-priority pair (for consideration by the low-priority pair).
      $active_tower_cnt_for_low_priority[1:0] = $active_tower_cnt + {1'b0, $new_priority_tower};
      $win = $maxed_tower_cnt[2:0] >= 3;
      
      // Bust if no tower heights change.
      $bust = ! | /tower[*]$grow;
      $turn_over = $end_turn || $bust;
   
      \viz_js
         box: {strokeWidth: 0},
         template: {
            action: [
               "Text", "", {
                  left: 18, top: 72,
                  fontSize: 8, fontFamily: "Roboto", fill: "black"
               }
            ]
         },
         render() {
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
   
   /header_player[m5_PLAYER_RANGE]
      \viz_js
         box: {width: 100, height: 15, fill: "#a0e0a0", strokeWidth: 0},
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
            m5_player_color(i)
            o.circle.set({fill: player_color,
                          stroke: '/top/active_player$win'.asBool() && ('/top$Player'.asInt() == i) ? "cyan" : "gray"})
            o.id.set({text: i == 0 ? "m5_get_ago(player_id, 0)" :
                            i == 1 ? "m5_get_ago(player_id, 1)" :
                            i == 2 ? "m5_get_ago(player_id, 2)" :
                            i == 3 ? "m5_get_ago(player_id, 3)" :
                                     "m5_get_ago(player_id, 4)"})
         },
         where: {left: -25, top: 3, width: 50, height: 8, justifyX: "center", justifyY: "bottom"},
   
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = /active_player$win;
   *failed = *cyc_cnt > 400;
\SV
   m5_makerchip_module
\TLV
   m5+eleven_towers_game()
\SV
   endmodule
