\m5_TLV_version 1d --inlineGen: tl-x.org
\m5
   / The Second Annual Makerchip ASIC Showdown, Summer 2026: Eleven Towers
   / This file is the library providing the content.
   / See the repo's README.md for more information.

   / A library for Makerchip that provides a game with gameplay similar to the
   / Can't Stop game from Parker Brothers.
   
   use(m5-1.0)
   
   
   / Provide a library defining a team's control circuit, name, and ID.
   fn(team_raw_tlv, ?TlvFile, {
      / Include submitted TLV URL, reporting an error if it produces text output.
      if_null(m4_include_lib(m5_TlvFile), [
         error(['The following TL-Verilog library produced output text. Ignoring']m5_nl    m5_TlvFile)
      ])
      on_return(var, github_id, m5_github_id)   /// Preserve what the library defined after it gets popped by the return.
      on_return(var, team_name, m5_team_name)   ///   "
   })
   
   var(num_players, 0)  // incremented as defined
   
   / Define which TLV macro to use for this player.
   / E.g. m5_define_player(random, Joe Random)  /// to define a "Joe Random" player with predefined random behavior from m5_player_random
   fn(define_player, PlayerId, PlayerName, {
      on_return(var, github_id, m5_PlayerId)
      on_return(var, player_name, m5_PlayerName)
      on_return(increment, ['num_players'])
   })

   / Macro to get player color from render().
   / $1: Player index
   macro(player_color, ['let player_color = this.getScope("top").context.player_color[$1]'])

   macro(DefaultTeamVizBoxAndWhere, ['box: {width: 210, height: 105, left: -55, top: -2.5, strokeWidth: 0}, where: {left: 0, top: 0, width: 80, height: 120},'])
   

   macro(configure, [
      define_hier(PLAYER, m5_num_players)

      var(die_size, 7.2)
      var(die_stroke_width, 0)
      var(pip_radius, 0.78)
      /Characterize the layout of pieces on the tower.
      var(piece_height, 10)
      var(piece_width, 10)
      var(piece_layout_left, (2.5 - 0.2 * m5_PLAYER_CNT))
      var(tower_separation, (11 + m5_PLAYER_CNT * 1.5))
      var(piece_layout_top, -1.0)
      var(tower_left, (m5_tower_separation - m5_piece_width) / 2)
      var(active_tower_width, m5_piece_width)

      / Push random players and names if github_id's are not already defined.
      repeat(m5_PLAYER_CNT, [
         if(m5_depth_of(github_id) < m5_PLAYER_CNT, [
            var(github_id, random)
         ])
      ])
      repeat(m5_PLAYER_CNT, [
         if(m5_depth_of(player_name) < m5_PLAYER_CNT, [
            var(player_name, Random Player m5_LoopCnt)
         ])
      ])

      / VIZ config
      / VIZ_mode can be set before including this library.
      /   devel: [default] for development
      /   demo: optimized for demonstration
      if_var_ndef(VIZ_mode, [
         var(VIZ_mode, devel)
      ])
      case(VIZ_mode, devel, [
      ], [
      ])

      var(Uniquifier, 0)   /// Used to provide unique names.
   ])
   
// --------------- For the Verilog template ---------------

\TLV verilog_wrapper(/_top, _github_id)
   \SV_plus
      m5_increment(Uniquifier, 1)
      logic signed [7:0] id['']m5_Uniquifier['']energy [m5_SHIP_RANGE];
      logic signed [7:0] id['']m5_Uniquifier['']x [m5_SHIP_RANGE];
      logic signed [7:0] id['']m5_Uniquifier['']y [m5_SHIP_RANGE];
      logic signed [7:0] id['']m5_Uniquifier['']enemy_x_p [m5_SHIP_RANGE];
      logic signed [7:0] id['']m5_Uniquifier['']enemy_y_p [m5_SHIP_RANGE];
      logic signed [3:0] id['']m5_Uniquifier['']x_a [m5_SHIP_RANGE];
      logic signed [3:0] id['']m5_Uniquifier['']y_a [m5_SHIP_RANGE];
      logic [1:0] id['']m5_Uniquifier['']fire_dir [m5_SHIP_RANGE];
      team_['']_github_id team_['']_github_id['_']m5_Uniquifier[''](
         // Inputs:
         .clk(clk),
         .reset(/_top$reset),
         .x(id['']m5_Uniquifier['']x),
         .y(id['']m5_Uniquifier['']y),
         .energy(id['']m5_Uniquifier['']energy),
         .destroyed(/ship[*]>>1$destroyed),
         .enemy_x_p(id['']m5_Uniquifier['']enemy_x_p),
         .enemy_y_p(id['']m5_Uniquifier['']enemy_y_p),
         .enemy_cloaked(/enemy_ship[*]$cloaked),
         .enemy_destroyed(/enemy_ship[*]$destroyed),
         // Outputs:
         .x_a(id['']m5_Uniquifier['']x_a),
         .y_a(id['']m5_Uniquifier['']y_a),
         .attempt_fire(/ship[*]$$attempt_fire),
         .attempt_shield(/ship[*]$$attempt_shield),
         .attempt_cloak(/ship[*]$$attempt_cloak),
         .fire_dir(id['']m5_Uniquifier['']fire_dir)
      );
   /enemy_ship[*]
      \SV_plus
         assign *id['']m5_Uniquifier['']enemy_x_p[enemy_ship] = $xx_p;
         assign *id['']m5_Uniquifier['']enemy_y_p[enemy_ship] = $yy_p;
   /ship[*]
      \SV_plus
         assign *id['']m5_Uniquifier['']x[ship] = >>1$xx_p;
         assign *id['']m5_Uniquifier['']y[ship] = >>1$yy_p;
         assign *id['']m5_Uniquifier['']energy[ship] = >>1$energy;
         assign $$xx_acc[3:0] = *id['']m5_Uniquifier['']x_a[ship];
         assign $$yy_acc[3:0] = *id['']m5_Uniquifier['']y_a[ship];
         assign $$fire_dir[1:0] = *id['']m5_Uniquifier['']fire_dir[ship];
      //$xx_acc[3:0] = /_top$xx_acc_vect[4 * (ship + 1) - 1 : 4 * ship];
      //$yy_acc[3:0] = /_top$yy_acc_vect[4 * (ship + 1) - 1 : 4 * ship];
      //$fire_dir[1:0] = /_top$fire_dir_vect[2 * (ship + 1) - 1 : 2 * ship];

// Reference player logic providing the following interface.
//
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
//
// Random
\TLV team_random(/_top)
   /pairing[2:0]
      m4_rand($rand, 31, 0, pairing)
      $score[7:0] = $rand % 256;
      $priority_pair[0:0] = 1'b0;
   m4_rand($end_turn, 0, 0)
// Choose a pairing with seven if possible. Play 5 times.
\TLV team_seven(/_top)
   /pairing[2:0]
      /pair[1:0]
         $is_seven = $sum == 4'd7;
      $score[0:0] = /pair[*]$is_seven;
      $priority_pair[0:0] = 1'b0;
   $PlayCnt[2:0] <= $my_turn ? $PlayCnt + 3'b1 : 3'b0;
   $end_turn = $PlayCnt > 3'd5;
   
// Logic shared by /_top/player#
\TLV player_logic(/_top, _player_num)
   /player['']_player_num
      $reset = /_top$reset;
      $my_turn = _player_num == /_top$Player;
      `BOGUS_USE($my_turn)
      /pairing[2:0]
         //$ANY = /_top/pairing$ANY;
         /pair[1:0]
            $ANY = /_top/pairing/pair$ANY;
            /die[1:0]
               $ANY = /_top/pairing/pair/die$ANY;
               `BOGUS_USE($value)
         /* verilator lint_save */
         /* verilator lint_off width */
         $score16[15:0] = $score;
         /* verilator lint_restore */
      m5_var(my_github_id, m5_get_ago(github_id, _player_num))
      m5+call(team_\m5_my_github_id)

\TLV define_players(/_top)
   // TODO: We're using fixed indentation here. Need to update tlv_lib to use M5.
   m5_repeat(m5_num_players, ['m5_nl()         m5+player_logic(/_top, m5_LoopCnt)m5_nl'])

\TLV eleven_towers_game(/_top)
   m5_configure()
   
   $reset = *reset;
   
   \SV_plus
      logic[3:0] *max[12:2] = {4'd2, 4'd4, 4'd6, 4'd8, 4'd10, 4'd12, 4'd10, 4'd8, 4'd6, 4'd4, 4'd2};
   
   
   
   // -------------------------
   // Game State
   
   // Which player's turn is it?
   $next_player[m5_PLAYER_INDEX_RANGE] =
        $Player == m5_PLAYER_MAX ? m5_PLAYER_INDEX_HIGH'd0 :
                                   $Player + m5_PLAYER_INDEX_HIGH'd1;
   $Player[m5_PLAYER_RANGE] <=
        $reset                   ? 1'b0 :
        /active_player$turn_over ? $next_player :
                                   $RETAIN;
   
   /active_player
      /tower[12:2]
         \viz_js
            box: {width: m5_tower_separation, height: 170, strokeWidth: 0},
            layout: "horizontal",
            init() {
               this.tower_heights = [2, 4, 6, 8, 10, 12, 10, 8, 6, 4, 2]
               
               this.top = function (pos) {
                  return 2 + 12 * (13 - pos)
               }
               
               this.makeRect = function (pos, color, z) {
                  return new fabric.Rect({left: m5_tower_left + z * m5_piece_layout_left, top: this.top(pos) + z * m5_piece_layout_top,
                                          width: m5_active_tower_width, height: m5_piece_height,
                                          fill: color, strokeWidth: 0,
                                        })
               }
               
               let ret = {}
               
               // Towers.
               let height = this.tower_heights[this.getIndex() - 2]
               for (let i = 1; i <= height + 1; i++) {
                  ret[i] = this.makeRect(i, pos == height + 1 ? "#303030" : "#707070", 0)
               }
               
               // Tower numbers.
               let props = {originX: "center", originY: "center", fill: "white", fontSize: 6, fontFamily: "Roboto"}
               let index_str = this.getIndex().toString()
               ret.tower_num_circle = new fabric.Circle({radius: 6, left: m5_tower_separation / 2, top: this.top(0) + m5_piece_height / 2,
                                                         originX: "center", originY: "center", fill: "transparent"})
               ret.tower_num_bottom = new fabric.Text(index_str, {left: m5_tower_separation / 2, top: this.top(0) + m5_piece_height / 2, ...props})
               ret.tower_num_top = new fabric.Text(index_str, {left: m5_tower_separation / 2, top: this.top(height + 1) + m5_piece_height / 2, ...props})
               this.tower_num_top_set = false
               
               return ret
            },
            render() {
               let tower = this.getIndex()
               let objs = this.getObjects()
               let active_player = '/_top$Player'.asInt()
               
               //
               // Tower background and highlighting.
               //
               
               // Background square gray colors.
               for (let i = 1; i <= '$max'.asInt() + 1; i++) {
                  objs[i].set({fill: (i == '$max'.asInt() + 1
                                         ? ('$next_active'.asBool() ? "#a0a0a0" : "#303030")
                                         : "#707070"
                  )})
               }
               
               // Circle the pair numbers.
               let pair0_matches = '/chosen_pair[0]$matches'.asBool()
               let pair1_matches = '/chosen_pair[1]$matches'.asBool()
               let both_match = pair0_matches && pair1_matches
               let color = both_match    ? "#808080A0" :
                           pair0_matches ? "#FFFFFF60" :
                           pair1_matches ? "#00000060" :
                                           "transparent"
               objs.tower_num_circle.set({fill: color})
               
               
               //
               // Place player pieces.
               //
               
               // Determine the pieces in this tower.
               let pieces = []  // each entry, if defined, is a list of pieces for the indexed height.
               for (let player = 0; player < m5_PLAYER_CNT; player++) {
                  let height = '/_top/player[player]/tower[tower]$Height'.asInt()
                  if (pieces[height]) {
                     pieces[height].push(player)
                  } else {
                     pieces[height] = [player]
                  }
               }
               
               // Remove [0], which is not on the board.
               delete pieces[0]
               
               // Properly order and create the pieces.
               let ret = []
               for (let height in pieces) {
                  
                  // If there are multiple pieces at this height, determine their proper order.
                  if (pieces.length > 1) {
                     // Need to determine order.
                     let ordered = []  // pieces[height] properly ordered
                     // Search back in time, removing players.
                     let step = 0
                     do {
                        pieces[height].forEach((player, i) => {
                           // If this player was played this step, remove it from pieces[height]
                           // and add it to ordered.
                           let h = '/_top/player[player]/tower[tower]$Height'.step(step).asInt(null)
                           if (h === null) {
                              console.log(`\VIZ BUG: Didn''t find cycle at which player ${player} reached height ${height} in tower ${tower}.`)
                              pieces[height] = []
                           } else if (h != height) {
                              pieces[height].splice(i, 1)
                              ordered.unshift(player)
                           }
                        })
                        step--
                     } while(pieces[height].length)
                     // Replace pieces[height] with the properly ordered list.
                     pieces[height] = ordered
                  }
                  
                  // Create the pieces.
                  pieces[height].forEach((player, i) => {
                     console.log(`Piece: tower: ${tower}, height: ${height}, player: ${player}, i: ${i}`)
                     m5_player_color(player)
                     ret.push(this.makeRect(height, player_color, i))
                  })
               }
               
               // Add the turn marker, if there is one.
               let turn_height = '$my_next_turn_height'.asInt()
               if (turn_height > '/_top/player[active_player]/tower[tower]$Height'.asInt()) {
                  ret.push(this.makeRect(turn_height, "white", pieces[turn_height] ? pieces[turn_height].length : 0))
               }
               
               return ret
            },
            where: {left: -m5_tower_separation * 5.5, top: 0},
      \viz_js
         box: {left: -105, top: 0, width: 210, height: 170, strokeWidth: 0},
         where: {left: -40, top: 17, width: 80, height: 56, justifyX: "center", justifyY: "top"},
            
   /m5_PLAYER_HIER
      /tower[12:2]
         $max[3:0] = *max\[#tower\];
         $max_height[3:0] = *max\[#tower\] + 1;
         $Height[3:0] <=
              /_top$reset ? 4'b0 :
              ! /_top/active_player$end_turn || /_top/active_player$bust
                          ? $RETAIN :
              // successful end-of-turn
              /_top$Player == #player  // for me
                          ? /_top/active_player/tower$my_next_turn_height :
              // for my opponent
              /_top/active_player/tower$my_next_turn_height >= $max_height
                          // and this tower is complete for them
                          ? 4'b0 :
              // and they did not complete this tower
                            $RETAIN;
         // Reached the max (claimed the tower).
         $maxed = $Height == $max_height;
   
   // -------------------------
   // Dice
   
   // Four rolled dice values.
   /die[3:0]
      $value[2:0] = $random[31:0] % 6 + 1;
      \viz_js
         box: {width: 10, height: 10, strokeWidth: 0},
         render() {
            let top_context = this.getScope("top").context
            let pip_color = this.getIndex("die") == 0 || '/_top/active_player/pairing[(this.getIndex("die") + 2) % 3]$chosen'.asBool() ? "white" : "black"
            return [top_context.die('/_top$Player'.asInt(), pip_color, '$value'.asInt(), 5, 5, 1)]
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
         $my_height[3:0] = /_top/player[/_top$Player]/tower[$sum]$Height;
         // Height for this turn.
         $turn_height[3:0] = /_top/active_player/tower[$sum]$TurnHeight;
         // Not for > 2 players
         //$opponent_height[3:0] = /_top/player[~ /_top$Player]/tower[$sum]$Height;
         $max_height[3:0] = *max\[$sum\] + 1;
         // These may or may not be used by the players.
         `BOGUS_USE($my_height $turn_height /*$opponent_height*/ $max_height)
         /die[1:0]
            $value[2:0] = /_top/die[
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
   m5+define_players(/_top)
   
   /active_player
      $ANY = m5_repeat(m5_calc(m5_num_players-1), ['/_top$Player == m5_LoopCnt ? /_top/player\m5_LoopCnt$ANY : ']) /_top/player\m5_calc(m5_num_players-1)$ANY;
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
         $ANY = m5_repeat(m5_calc(m5_num_players-1), ['/_top$Player == m5_LoopCnt ? /_top/player\m5_LoopCnt/pairing$ANY : ']) /_top/player\m5_calc(m5_num_players-1)/pairing$ANY;
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
            $ANY = m5_repeat(m5_calc(m5_num_players-1), ['/_top$Player == m5_LoopCnt ? /_top/player\m5_LoopCnt/pairing/pair$ANY : ']) /_top/player\m5_calc(m5_num_players-1)/pairing/pair$ANY;
            `BOGUS_USE($sum)
            /die[1:0]
               $ANY = m5_repeat(m5_calc(m5_num_players-1), ['/_top$Player == m5_LoopCnt ? /_top/player\m5_LoopCnt/pairing/pair/die$ANY : ']) /_top/player\m5_calc(m5_num_players-1)/pairing/pair/die$ANY;
               \viz_js
                  box: {width: 10, height: 10, strokeWidth: 0},
                  layout: "horizontal",
                  render() {
                     let top_context = this.getScope("top").context
                     let pip_color = this.getIndex("pair") ? "black" : "white"
                     return [top_context.die('/_top$Player'.asInt(), pip_color, '$value'.asInt(), 5, 5, 1)]
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
         $ANY = /_top/player[/_top$Player]/tower$ANY;
         $max_height[3:0] = *max\[#tower\] + 1;
         // Blocked if any player is at max.
         // Specifically for 2-player.
         ///other_players_tower
         //   $ANY = /_top/player[! /_top$Player]/tower$ANY;
         // Determine whether this tower is blocked (any player is maxed).
         /m5_PLAYER_HIER
            $maxed = /_top/player/tower$maxed;
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
              /_top$reset              ? 4'b0 :
              // If end turn, set height for next player.
              /active_player$turn_over ? /_top/player[(/_top$Player + m5_PLAYER_INDEX_HIGH'd1) % m5_PLAYER_CNT]/tower<<1$Height :
                                         $my_next_turn_height;
         $active = $TurnHeight != $Height;
         $next_active = $my_next_turn_height != $Height;   // (for VIZ only)
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
                          stroke: '/_top/active_player$win'.asBool() && ('/_top$Player'.asInt() == i) ? "cyan" : "gray"})
            o.id.set({text: i == 0 ? "m5_get_ago(github_id, 0)" :
                            i == 1 ? "m5_get_ago(github_id, 1)" :
                            i == 2 ? "m5_get_ago(github_id, 2)" :
                            i == 3 ? "m5_get_ago(github_id, 3)" :
                                     "m5_get_ago(github_id, 4)"})
         },
         where: {left: -25, top: 3, width: 50, height: 8, justifyX: "center", justifyY: "bottom"},
   
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = /active_player$win;
   *failed = *cyc_cnt > 400;

   
   
\SV
   m5_makerchip_module
\TLV
   // Define players/teams.
   m5_define_player(random, Random 1)
   m5_define_player(random, Random 2)
   m5_define_player(seven, Seven)
   
   // Instantiate the Showdown environment.
   m5+eleven_towers_game(/top)
\SV
   endmodule
