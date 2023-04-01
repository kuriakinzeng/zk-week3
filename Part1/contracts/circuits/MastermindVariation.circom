pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template MastermindVariation() {
// Public inputs
    signal input pubGuessA;
    signal input pubGuessB;
    signal input pubGuessC;
    signal input pubGuessD;
    signal input pubNumRed;
    signal input pubNumWhite;
    signal input pubSolnHash;

    // Private inputs
    signal input privSolnA;
    signal input privSolnB;
    signal input privSolnC;
    signal input privSolnD;
    signal input privSalt;

    // Output
    signal output solnHashOut;

    var guess[4] = [pubGuessA, pubGuessB, pubGuessC, pubGuessD];
    var soln[4] =  [privSolnA, privSolnB, privSolnC, privSolnD];
    var j = 0;
    var k = 0;
    component lessThan[8];
    component equalGuess[6];
    component equalSoln[6];
    var equalIdx = 0;

    // Create a constraint that the solution and guess digits are all less than 6.
    for (j=0; j<4; j++) {
        lessThan[j] = LessThan(4);
        lessThan[j].in[0] <== guess[j];
        lessThan[j].in[1] <== 6;
        lessThan[j].out === 1;
        lessThan[j+4] = LessThan(4);
        lessThan[j+4].in[0] <== soln[j];
        lessThan[j+4].in[1] <== 6;
        lessThan[j+4].out === 1;
        for (k=j+1; k<4; k++) {
            // Create a constraint that the solution and guess digits are unique. no duplication.
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guess[j];
            equalGuess[equalIdx].in[1] <== guess[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== soln[j];
            equalSoln[equalIdx].in[1] <== soln[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }
    }

    // Count red & white pins
    var red = 0;
    var white = 0;
    component equal[16];

    for (j=0; j<4; j++) {
        for (k=0; k<4; k++) {
            equal[4*j+k] = IsEqual();
            equal[4*j+k].in[0] <== soln[j];
            equal[4*j+k].in[1] <== guess[k];
            white += equal[4*j+k].out;
            if (j == k) {
                red += equal[4*j+k].out;
                white -= equal[4*j+k].out;
            }
        }
    }

    // Create a constraint around the number of red pins
    component equalRed = IsEqual();
    equalRed.in[0] <== pubNumHit;
    equalRed.in[1] <== red;
    equalRed.out === 1;
    
    // Create a constraint around the number of white pins
    component equalWhite = IsEqual();
    equalWhite.in[0] <== pubNumWhite;
    equalWhite.in[1] <== white;
    equalWhite.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(5);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnA;
    poseidon.inputs[2] <== privSolnB;
    poseidon.inputs[3] <== privSolnC;
    poseidon.inputs[4] <== privSolnD;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
}

component main {public [pubGuessA, pubGuessB, pubGuessC, pubGuessD, pubNumRed, pubNumWhite, pubSolnHash]} = MastermindVariation();