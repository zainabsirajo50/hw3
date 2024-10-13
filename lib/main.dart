import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: CardGridApp(),
    ),
  );
}

class GameState extends ChangeNotifier {
  List<CardModel> cards = [];
  List<int> flippedCardIndices = []; // Track indices of currently flipped cards.

  GameState() {
    _initializeCards();
  }

  // Initialize the cards with front and back designs.
  void _initializeCards() {
    List<String> frontContent = [
      'A', 'A', 'B', 'B', 'C', 'C', 'D', 'D',
      'E', 'E', 'F', 'F', 'G', 'G', 'H', 'H'
    ];

    frontContent.shuffle(); // Shuffle the cards to randomize the order.

    cards = List.generate(16, (index) {
      return CardModel(
        front: "Back Design",   // Front is String.
        back: frontContent[index],          // Back is also a String.
      );
    });
  }

  // Method to flip a card and manage game logic.
  void flipCard(int index) {
    if (!cards[index].isFaceUp && flippedCardIndices.length < 2) {
      cards[index].isFaceUp = true;
      flippedCardIndices.add(index);

      notifyListeners();

      if (flippedCardIndices.length == 2) {
        _checkForMatch();
      }
    }
  }

  // Check if the two flipped cards match.
  void _checkForMatch() {
    final firstIndex = flippedCardIndices[0];
    final secondIndex = flippedCardIndices[1];

    if (cards[firstIndex].front == cards[secondIndex].front) {
      // Cards match, keep them face-up.
      flippedCardIndices.clear();
    } else {
      // Cards do not match, flip them back after a delay.
      Future.delayed(Duration(seconds: 1), () {
        cards[firstIndex].isFaceUp = false;
        cards[secondIndex].isFaceUp = false;

        flippedCardIndices.clear();
        notifyListeners();
      });
    }
  }

  // Reset the game (all cards face-down).
  void resetGame() {
    for (var card in cards) {
      card.isFaceUp = false;
    }
    flippedCardIndices.clear();
    notifyListeners();
  }
}

class CardModel {
  final String front; // Front side of the card, type String.
  final String back;  // Back side of the card, type String.
  bool isFaceUp;

  CardModel({
    required this.front,
    required this.back,
    this.isFaceUp = false,  // Default to face-down.
  });
}

class CardGridApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Card Matching Game"),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                Provider.of<GameState>(context, listen: false).resetGame();
              },
            )
          ],
        ),
        body: CardGrid(),
      ),
    );
  }
}

class CardGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Consumer<GameState>(
        builder: (context, gameState, child) {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // Adjust to 4x4 grid (for 6x6, set this to 6)
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
            ),
            itemCount: gameState.cards.length,
            itemBuilder: (context, index) {
              final card = gameState.cards[index];
              return GestureDetector(
                onTap: () {
                  gameState.flipCard(index);
                },
                child: FlipCard(card: card),
              );
            },
          );
        },
      ),
    );
  }
}

class FlipCard extends StatefulWidget {
  final CardModel card;

  const FlipCard({Key? key, required this.card}) : super(key: key);

  @override
  _FlipCardState createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400), // Control the speed of the flip
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.card.isFaceUp) {
      _controller.forward(); // Animate to face-up
    } else {
      _controller.reverse(); // Animate to face-down
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        // Get rotation value in radians (flip horizontally on Y-axis)
        double rotationValue = _flipAnimation.value * pi;

        // If the value is beyond 90 degrees (pi/2), we reverse the content of the card
        bool isFrontVisible = rotationValue <= pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective to make the flip more realistic
            ..rotateY(rotationValue),
          alignment: Alignment.center,
          child: isFrontVisible ? _buildFrontCard() : _buildBackCard(),
        );
      },
    );
  }

  Widget _buildFrontCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(2, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.card.front, // Front content (text or image)
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey, // Back design color
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(2, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.card.back, // Back content (text or image)
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}