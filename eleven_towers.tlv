\m5_TLV_version 1d: tl-x.org
\m5
   / A library for Makerchip that provides a game with gameplay similar to the
   / Connect 4 game from Hasbro.
   
   use(m5-1.0)
   / Player IDs should be defined by each player's library file using
   / var(player_id, xxx)
   / thus defining a stack of player_ids.
   
   var(player0_color, "#d01010")
   var(player1_color, "#d0d010")
   var(die_size, 7)
   var(die_stroke_width, 0.15)
   var(pip_radius, 0.8)
   
   / Push up to two random players if player_id's are not already defined.
   repeat(2, [
      if(m5_depth_of(player_id) < 2, [
         var(player_id, random)
      ])
   ])
   
// Player logic providing random choice.
// The highest score is chosen.
// Input:
//   /pairing[2:0]
//      /pair[1:0]
//         /die[1:0]
//            $value[2:0]
// Output:
//   /pairing[2:0]
//      $score[?:0] = ...;
\TLV player_random(/_top)
   /pairing[2:0]
      m4_rand($rand, 31, 0)
      $score[7:0] = $rand % 256;

\TLV eleven_towers_game()
   // Reset, delayed by one cycle, so we have an empty board on cycle 0.
   $real_reset = *reset;
   $reset = >>1$real_reset;
   
   // Which player's turn is it?
   $Player <= $reset ? 1'b0 : ! $Player;
   
   \viz_js
      box: {left: -50, top: 0, width: 100, height: 100, fill: "gray"},
      init() {
         // Create a die.
         this.die = function (value, left, top, scale) {
            debugger
            pip = function (left, top) {
               return new fabric.Circle(
                  {left, top, radius: m5_pip_radius,
                   fill: "black", strokeWidth: 0, originX: "center", originY: "center"
                  }
               )
            }
            let die = new fabric.Group(
               [new fabric.Rect(
                  {width: m5_die_size + m5_die_stroke_width, height: m5_die_size + m5_die_stroke_width,
                   rx: 0.8, ry: 0.8,
                   originX: "center", originY: "center",
                   fill: "white", strokeWidth: m5_die_stroke_width, stroke: "gray",
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
   
   \SV_plus
      logic[3:0] *max[12:2] = {4'd2, 4'd4, 4'd6, 4'd8, 4'd10, 4'd12, 4'd10, 4'd8, 4'd6, 4'd4, 4'd2};
   /player[1:0]
      /tower[12:2]
         $max[3:0] = *max\[#tower\];
         $height[3:0] = /top$reset ? 4'b0 : 4'b0;
         \viz_js
            box: {width: 14, height: 151, stroke: "green"},
            init() {
               debugger
               let ret = {}
               for(let i = 0; i < 13; i++) {
                  ret[i] =
                       new fabric.Rect({left: 7, top: 7 + 12 * (12 - i), originX: "center", originY: "center",
                                        width: 10, height: 10,
                                        fill: "transparent", strokeWidth: 0,
                                      })
               }
               return ret
            },
            render() {
               let objs = this.getObjects()
               let player = this.getIndex("player")
               let color = player ? m5_player1_color : m5_player0_color
               for(let i = 0; i < 13; i++) {
                  objs[i].set({fill: i > '$max'.asInt()     ? "transparent" :
                                     i == '$max'.asInt()    ? "#303030" :
                                     i >= '$height'.asInt() ? "transparent" :
                                                              color})
               }
            },
            where: {left: -30, top: 20, width: 60, height: 50, justifyX: "center", justifyY: "top"},
      \viz_js
         layout: {left: 0.9, top: -0.7},
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
   /player0
      m5+call(['player_']m5_get_ago(player_id, 0), /player0)
   /player1
      m5+call(['player_']m5_get_ago(player_id, 1), /player1)
   /active_player
      /pairing[2:0]
         $ANY = /top$Player ? /top/player1/pairing$ANY : /top/player0/pairing$ANY;
         `BOGUS_USE($score)
      /tower[12:2]
         $ANY = /top/player[/top$Player]/tower[#tower]$ANY;
         `BOGUS_USE($height)
   
   // Four rolled dice values.
   /die[3:0]
      $value[2:0] = $random[31:0] % 6 + 1;
      \viz_js
         box: {width: 10, height: 10},
         render() {
            return [this.getScope("top").context.die('$value'.asInt(), 5, 5, 1)]
         },
         where: {left: -15, top: 73, width: 30, height: 10, justifyX: "center", justifyY: "bottom"}
   
   // Possible die pairings:
   //   Pair: 0       1
   //   Die:0  1    0  1
   //   0: [0, 1], [2, 3]
   //   1: [0, 2], [1, 3]
   //   2: [0, 3], [1, 2]
   /pairing[2:0]
      \viz_js
         layout: {left: 0, top: 15},
         where: {left: -8, top: 86, width: 16, height: 10, justifyX: "center", justifyY: "bottom"},
      /pair[1:0]
         \viz_js
            layout: {left: 25, top: 0},
         /die[1:0]
            $value[2:0] = /top/die[
                 #pair == 0 ? #pairing * #die + #die \:
                 #die == 1  ? (#pairing == 0 ? 2 \: 1) \:
                              (#pairing == 2 ? 2 \: 3)
               ]$value;
            \viz_js
               box: {width: 10, height: 10},
               layout: "horizontal",
               render() {
                  return [this.getScope("top").context.die('$value'.asInt(), 5, 5, 1)]
               },
   /sum[2:12]
      /player[1:0]
         $reset = /top$reset;
         $height[3:0] = $reset ? 4'b0 : 4'b0;
         
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   m5_makerchip_module
\TLV
   m5+eleven_towers_game()
\SV
   endmodule
