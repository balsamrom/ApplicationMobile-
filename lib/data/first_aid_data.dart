import '../models/first_aid_item.dart';

const List<FirstAidItem> firstAidItems = [
  FirstAidItem(
    title: "Arrêt cardiaque",
    priority: Priority.critique,
    timeToAction: "Moins de 3 minutes",
    description: "L'arrêt cardiaque est une interruption brutale de la circulation sanguine efficace due à l'incapacité du cœur à se contracter.",
    materials: ["Vos mains", "Un téléphone pour appeler les urgences"],
    steps: [
      "Assurez la sécurité de la zone.",
      "Vérifiez la respiration de l'animal.",
      "Commencez le massage cardiaque.",
      "Appelez immédiatement un vétérinaire."
    ],
  ),
  FirstAidItem(
    title: "Hémorragie",
    priority: Priority.urgent,
    timeToAction: "Moins de 5-10 minutes",
    description: "Une hémorragie est une perte de sang importante et rapide qui peut mettre la vie de l'animal en danger.",
    materials: ["Gants", "Compressez stériles ou un linge propre", "Bande de gaze ou un lien"],
    steps: [
      "Exercez une pression directe sur la plaie.",
      "Surélevez le membre si possible.",
      "Appliquez un pansement compressif.",
      "Consultez un vétérinaire en urgence."
    ],
  ),
  FirstAidItem(
    title: "Intoxication",
    priority: Priority.urgent,
    timeToAction: "Variable (contactez un vétérinaire)",
    description: "L'ingestion de substances toxiques peut provoquer des symptômes graves et nécessite une intervention rapide.",
    materials: ["Téléphone", "Informations sur le produit ingéré"],
    steps: [
      "Identifiez la substance si possible.",
      "Ne faites pas vomir l'animal sans avis vétérinaire.",
      "Appelez le centre anti-poison ou votre vétérinaire.",
      "Suivez les instructions du professionnel."
    ],
  ),
  FirstAidItem(
    title: "Coup de chaleur",
    priority: Priority.modere,
    timeToAction: "Moins de 15-20 minutes",
    description: "Le coup de chaleur survient lorsque l'animal n'arrive plus à réguler sa température corporelle.",
    materials: ["Serviettes humides et fraîches", "Eau fraîche (pas glacée)", "Ventilateur"],
    steps: [
      "Déplacez l'animal à l'ombre.",
      "Refroidissez-le progressivement avec de l'eau et des linges humides.",
      "Proposez-lui à boire en petite quantité.",
      "Consultez un vétérinaire même si l'état s'améliore."
    ],
  ),
];
