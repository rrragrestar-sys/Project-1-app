import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

/// A standalone page to demonstrate Forge2D physics in Flame.
class PhysicsPlaygroundPage extends StatelessWidget {
  const PhysicsPlaygroundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forge2D Physics Playground'),
        backgroundColor: Colors.black,
      ),
      body: GameWidget(
        game: PhysicsGame(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Re-trigger the simulation or add more coins if needed
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

/// The main Game loop setup using Forge2D.
class PhysicsGame extends Forge2DGame with TapCallbacks {
  PhysicsGame() : super(gravity: Vector2(0, 15.0)); // Slightly higher gravity for better "game feel"

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Add boundaries (Floor)
    add(Floor(size: screenToWorld(canvasSize)));

    // 2. Add a dynamic coin dropping from the top
    add(Coin(initialPosition: Vector2(canvasSize.x / 2, 50)));
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // Add a coin wherever the user taps
    add(Coin(initialPosition: event.localPosition));
  }
}

/// A static Floor body that prevents objects from falling off screen.
class Floor extends BodyComponent {
  final Vector2 size;

  Floor({required this.size});

  @override
  Body createBody() {
    final shape = EdgeShape()..set(Vector2(0, size.y - 2), Vector2(size.x, size.y - 2));

    final fixtureDef = FixtureDef(shape)
      ..friction = 0.3
      ..restitution = 0.1; // Low bounciness for the floor itself

    final bodyDef = BodyDef(
      position: Vector2.zero(),
      type: BodyType.static,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    // Optionally render a line for the floor
    final paint = Paint()
      ..color = Colors.white.withAlpha(128)
      ..strokeWidth = 0.1
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(0, size.y - 2),
      Offset(size.x, size.y - 2),
      paint,
    );
  }
}

/// A dynamic Coin body that falls and bounces.
class Coin extends BodyComponent {
  final Vector2 initialPosition;

  Coin({required this.initialPosition});

  @override
  Body createBody() {
    // 1. Define the shape (a circle for a coin)
    // In Forge2D, sizes are in meters. 1.0 is quite large.
    final shape = CircleShape()..radius = 1.5;

    // 2. Define the fixture (properties of the material)
    final fixtureDef = FixtureDef(shape)
      ..density = 2.0      // Weight
      ..friction = 0.2     // Slipperiness
      ..restitution = 0.7; // Bounciness (0.0 to 1.0+)

    // 3. Define the body
    final bodyDef = BodyDef(
      position: initialPosition,
      type: BodyType.dynamic,
      angularDamping: 0.5, // Resists spinning over time
      linearDamping: 0.1,  // Resists movement over time
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    // Custom rendering for the coin
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD700), Color(0xFFB8860B)], // Gold gradient
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1.5))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, 1.5, paint);
    
    // Add a border
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, 1.5, borderPaint);
  }
}
