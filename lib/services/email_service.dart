import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // ⚠️  REPLACE WITH YOUR OWN CREDENTIALS ⚠️
  static const String _username = 'balsam.romdhane17@gmail.com';
  static const String _password = 'scwt rcaf twla tnsm'; // Use an app password for Gmail
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;

  static Future<void> sendPasswordResetEmail(String recipientEmail, String resetCode) async {
    final smtpServer = SmtpServer(
      _smtpHost,
      port: _smtpPort,
      username: _username,
      password: _password,
      ssl: false, // Use true for SSL, false for TLS/STARTTLS
      ignoreBadCertificate: false,
      allowInsecure: false,
    );

    final message = Message()
      ..from = Address(_username, 'PetCare App')
      ..recipients.add(recipientEmail)
      ..subject = 'Réinitialisation de votre mot de passe PetCare'
      ..html = """
        <h3>Réinitialisation de votre mot de passe</h3>
        <p>Bonjour,</p>
        <p>Vous avez demandé à réinitialiser votre mot de passe. Voici votre code de vérification :</p>
        <h2><b>$resetCode</b></h2>
        <p>Si vous n\'êtes pas à l\'origine de cette demande, vous pouvez ignorer cet e-mail.</p>
        <p>Merci,<br>L\'équipe PetCare</p>
      """;

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      throw Exception('Failed to send email.');
    }
  }
}
