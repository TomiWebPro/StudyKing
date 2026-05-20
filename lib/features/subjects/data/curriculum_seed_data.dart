
import 'package:studyking/core/utils/answer_comparator.dart';


class CurriculumSeedEntry {
  final String curriculumName;
  final List<SeedTopic> topics;

  const CurriculumSeedEntry({
    required this.curriculumName,
    required this.topics,
  });
}

class SeedTopic {
  final String title;
  final String description;
  final String syllabusText;
  final int sortOrder;
  final List<SeedTopic> subtopics;

  const SeedTopic({
    required this.title,
    this.description = '',
    this.syllabusText = '',
    this.sortOrder = 0,
    this.subtopics = const [],
  });
}

const curriculumSeedData = <CurriculumSeedEntry>[
  CurriculumSeedEntry(
    curriculumName: 'IB Chemistry',
    topics: [
      SeedTopic(
        title: 'Stoichiometric Relationships',
        description: 'Moles, empirical formulas, chemical equations, and reacting masses',
        syllabusText: 'Stoichiometric Relationships',
        sortOrder: 1,
        subtopics: [
          SeedTopic(title: 'Introduction to the particulate nature of matter', sortOrder: 1),
          SeedTopic(title: 'The mole concept', sortOrder: 2),
          SeedTopic(title: 'Reacting masses and volumes', sortOrder: 3),
        ],
      ),
      SeedTopic(
        title: 'Atomic Structure',
        description: 'Nuclear atom, electron configuration, and emission spectra',
        syllabusText: 'Atomic Structure',
        sortOrder: 2,
        subtopics: [
          SeedTopic(title: 'The nuclear atom', sortOrder: 1),
          SeedTopic(title: 'Electron configuration', sortOrder: 2),
        ],
      ),
      SeedTopic(
        title: 'Periodicity',
        description: 'Periodic trends, periodic table arrangement, and group properties',
        syllabusText: 'Periodicity',
        sortOrder: 3,
        subtopics: [
          SeedTopic(title: 'Periodic trends', sortOrder: 1),
          SeedTopic(title: 'Periodic trends: Group 1', sortOrder: 2),
          SeedTopic(title: 'Periodic trends: Group 2', sortOrder: 3),
          SeedTopic(title: 'Periodic trends: Group 17', sortOrder: 4),
          SeedTopic(title: 'Periodic trends: Group 18', sortOrder: 5),
          SeedTopic(title: 'Periodic trends: Transition metals', sortOrder: 6),
        ],
      ),
      SeedTopic(
        title: 'Chemical Bonding & Structure',
        description: 'Ionic, covalent, and metallic bonding; VSEPR theory; intermolecular forces',
        syllabusText: 'Chemical Bonding & Structure',
        sortOrder: 4,
        subtopics: [
          SeedTopic(title: 'Ionic bonding and structure', sortOrder: 1),
          SeedTopic(title: 'Covalent bonding', sortOrder: 2),
          SeedTopic(title: 'Covalent structures', sortOrder: 3),
          SeedTopic(title: 'Intermolecular forces', sortOrder: 4),
          SeedTopic(title: 'Metallic bonding', sortOrder: 5),
        ],
      ),
      SeedTopic(
        title: 'Energetics / Thermochemistry',
        description: 'Enthalpy changes, Hess\'s law, bond enthalpies, and calorimetry',
        syllabusText: 'Energetics / Thermochemistry',
        sortOrder: 5,
        subtopics: [
          SeedTopic(title: 'Measuring energy changes', sortOrder: 1),
          SeedTopic(title: 'Hess\'s law', sortOrder: 2),
          SeedTopic(title: 'Bond enthalpies', sortOrder: 3),
        ],
      ),
      SeedTopic(
        title: 'Chemical Kinetics',
        description: 'Collision theory, rate of reaction, factors affecting rate',
        syllabusText: 'Chemical Kinetics',
        sortOrder: 6,
        subtopics: [
          SeedTopic(title: 'Collision theory and rates of reaction', sortOrder: 1),
          SeedTopic(title: 'Rate expression', sortOrder: 2),
          SeedTopic(title: 'Activation energy', sortOrder: 3),
        ],
      ),
      SeedTopic(
        title: 'Equilibrium',
        description: 'Dynamic equilibrium, Le Chatelier\'s principle, equilibrium constant',
        syllabusText: 'Equilibrium',
        sortOrder: 7,
        subtopics: [
          SeedTopic(title: 'Equilibrium: Dynamic equilibrium', sortOrder: 1),
          SeedTopic(title: 'The equilibrium constant', sortOrder: 2),
        ],
      ),
      SeedTopic(
        title: 'Acids & Bases',
        description: 'Brønsted–Lowry theory, pH, strong vs weak acids, buffer solutions',
        syllabusText: 'Acids & Bases',
        sortOrder: 8,
        subtopics: [
          SeedTopic(title: 'Theories of acids and bases', sortOrder: 1),
          SeedTopic(title: 'Properties of acids and bases', sortOrder: 2),
          SeedTopic(title: 'The pH scale', sortOrder: 3),
          SeedTopic(title: 'Strong and weak acids and bases', sortOrder: 4),
          SeedTopic(title: 'Acid deposition', sortOrder: 5),
        ],
      ),
      SeedTopic(
        title: 'Redox Processes',
        description: 'Oxidation numbers, electrochemical cells, electrolysis, and corrosion',
        syllabusText: 'Redox Processes',
        sortOrder: 9,
        subtopics: [
          SeedTopic(title: 'Oxidation and reduction', sortOrder: 1),
          SeedTopic(title: 'Electrochemical cells', sortOrder: 2),
          SeedTopic(title: 'Electrolysis', sortOrder: 3),
        ],
      ),
      SeedTopic(
        title: 'Organic Chemistry',
        description: 'Functional groups, nomenclature, reaction mechanisms, and polymers',
        syllabusText: 'Organic Chemistry',
        sortOrder: 10,
        subtopics: [
          SeedTopic(title: 'Fundamentals of organic chemistry', sortOrder: 1),
          SeedTopic(title: 'Functional group chemistry', sortOrder: 2),
          SeedTopic(title: 'Reaction types', sortOrder: 3),
          SeedTopic(title: 'Synthetic routes', sortOrder: 4),
          SeedTopic(title: 'Stereoisomerism', sortOrder: 5),
        ],
      ),
      SeedTopic(
        title: 'Measurement & Data Processing',
        description: 'Uncertainty, error analysis, graphing, and data interpretation',
        syllabusText: 'Measurement & Data Processing',
        sortOrder: 11,
        subtopics: [
          SeedTopic(title: 'Uncertainties and errors in measurement', sortOrder: 1),
          SeedTopic(title: 'Graphical techniques', sortOrder: 2),
          SeedTopic(title: 'Spectroscopic identification', sortOrder: 3),
        ],
      ),
      SeedTopic(
        title: 'Atomic Structure (HL)',
        description: 'Atomic orbitals, electron spin, and the hydrogen emission spectrum',
        syllabusText: 'Atomic Structure (HL)',
        sortOrder: 12,
        subtopics: [
          SeedTopic(title: 'The angular momentum of the electron', sortOrder: 1),
          SeedTopic(title: 'Atomic orbitals', sortOrder: 2),
          SeedTopic(title: 'The hydrogen emission spectrum', sortOrder: 3),
        ],
      ),
      SeedTopic(
        title: 'The Periodic Table (HL)',
        description: 'Transition metal complex ions, colour, and catalytic properties',
        syllabusText: 'The Periodic Table (HL)',
        sortOrder: 13,
        subtopics: [
          SeedTopic(title: 'First-row d-block elements', sortOrder: 1),
          SeedTopic(title: 'Coloured complexes', sortOrder: 2),
        ],
      ),
      SeedTopic(
        title: 'Chemical Bonding (HL)',
        description: 'Hybridisation, molecular orbitals, and advanced VSEPR',
        syllabusText: 'Chemical Bonding (HL)',
        sortOrder: 14,
        subtopics: [
          SeedTopic(title: 'Hybridisation', sortOrder: 1),
          SeedTopic(title: 'Molecular orbital theory', sortOrder: 2),
        ],
      ),
      SeedTopic(
        title: 'Energetics (HL)',
        description: 'Born–Haber cycles, entropy, Gibbs free energy',
        syllabusText: 'Energetics (HL)',
        sortOrder: 15,
        subtopics: [
          SeedTopic(title: 'Born–Haber cycles', sortOrder: 1),
          SeedTopic(title: 'Entropy and spontaneity', sortOrder: 2),
          SeedTopic(title: 'Gibbs free energy', sortOrder: 3),
        ],
      ),
      SeedTopic(
        title: 'Kinetics (HL)',
        description: 'Rate-determining step, activation energy, Arrhenius equation',
        syllabusText: 'Kinetics (HL)',
        sortOrder: 16,
        subtopics: [
          SeedTopic(title: 'Rate expression and reaction mechanism', sortOrder: 1),
          SeedTopic(title: 'Activation energy (HL)', sortOrder: 2),
        ],
      ),
      SeedTopic(
        title: 'Equilibrium (HL)',
        description: 'Equilibrium constant, reaction quotient, Le Chatelier calculations',
        syllabusText: 'Equilibrium (HL)',
        sortOrder: 17,
        subtopics: [
          SeedTopic(title: 'The equilibrium constant (HL)', sortOrder: 1),
          SeedTopic(title: 'Equilibrium and Gibbs free energy', sortOrder: 2),
        ],
      ),
      SeedTopic(
        title: 'Acids & Bases (HL)',
        description: 'pH calculations, buffer solutions, titration curves, indicators',
        syllabusText: 'Acids & Bases (HL)',
        sortOrder: 18,
        subtopics: [
          SeedTopic(title: 'Lewis acids and bases', sortOrder: 1),
          SeedTopic(title: 'pH calculations (HL)', sortOrder: 2),
          SeedTopic(title: 'Buffer solutions', sortOrder: 3),
          SeedTopic(title: 'Titration curves', sortOrder: 4),
        ],
      ),
      SeedTopic(
        title: 'Redox Processes (HL)',
        description: 'Electrochemical cells, standard electrode potentials, electrolysis',
        syllabusText: 'Redox Processes (HL)',
        sortOrder: 19,
        subtopics: [
          SeedTopic(title: 'Standard electrode potentials', sortOrder: 1),
          SeedTopic(title: 'Electrolysis (HL)', sortOrder: 2),
        ],
      ),
      SeedTopic(
        title: 'Organic Chemistry (HL)',
        description: 'Reaction mechanisms, stereochemistry, and organic synthesis',
        syllabusText: 'Organic Chemistry (HL)',
        sortOrder: 20,
        subtopics: [
          SeedTopic(title: 'Reaction mechanisms', sortOrder: 1),
          SeedTopic(title: 'Synthetic routes (HL)', sortOrder: 2),
        ],
      ),
      SeedTopic(
        title: 'Measurement & Analysis (HL)',
        description: 'NMR spectroscopy, mass spectrometry, and chromatographic techniques',
        syllabusText: 'Measurement & Analysis (HL)',
        sortOrder: 21,
        subtopics: [
          SeedTopic(title: 'NMR spectroscopy', sortOrder: 1),
          SeedTopic(title: 'Mass spectrometry (HL)', sortOrder: 2),
          SeedTopic(title: 'Chromatography', sortOrder: 3),
        ],
      ),
    ],
  ),
  CurriculumSeedEntry(
    curriculumName: 'IB Biology',
    topics: [
      SeedTopic(title: 'Cell Biology', sortOrder: 1, subtopics: [
        SeedTopic(title: 'Introduction to cells', sortOrder: 1),
        SeedTopic(title: 'Ultrastructure of cells', sortOrder: 2),
        SeedTopic(title: 'Membrane structure', sortOrder: 3),
        SeedTopic(title: 'Membrane transport', sortOrder: 4),
        SeedTopic(title: 'The origin of cells', sortOrder: 5),
        SeedTopic(title: 'Cell division', sortOrder: 6),
      ]),
      SeedTopic(title: 'Molecular Biology', sortOrder: 2, subtopics: [
        SeedTopic(title: 'Molecules to metabolism', sortOrder: 1),
        SeedTopic(title: 'Water', sortOrder: 2),
        SeedTopic(title: 'Carbohydrates and lipids', sortOrder: 3),
        SeedTopic(title: 'Proteins', sortOrder: 4),
        SeedTopic(title: 'Enzymes', sortOrder: 5),
        SeedTopic(title: 'DNA and RNA structure', sortOrder: 6),
        SeedTopic(title: 'DNA replication, transcription, translation', sortOrder: 7),
        SeedTopic(title: 'Cell respiration', sortOrder: 8),
        SeedTopic(title: 'Photosynthesis', sortOrder: 9),
      ]),
      SeedTopic(title: 'Genetics', sortOrder: 3, subtopics: [
        SeedTopic(title: 'Genes', sortOrder: 1),
        SeedTopic(title: 'Chromosomes', sortOrder: 2),
        SeedTopic(title: 'Meiosis', sortOrder: 3),
        SeedTopic(title: 'Inheritance', sortOrder: 4),
        SeedTopic(title: 'Gene modification', sortOrder: 5),
      ]),
      SeedTopic(title: 'Ecology', sortOrder: 4, subtopics: [
        SeedTopic(title: 'Species and communities', sortOrder: 1),
        SeedTopic(title: 'Energy flow', sortOrder: 2),
        SeedTopic(title: 'Carbon cycling', sortOrder: 3),
        SeedTopic(title: 'Climate change', sortOrder: 4),
      ]),
      SeedTopic(title: 'Evolution & Biodiversity', sortOrder: 5, subtopics: [
        SeedTopic(title: 'Evidence for evolution', sortOrder: 1),
        SeedTopic(title: 'Natural selection', sortOrder: 2),
        SeedTopic(title: 'Biodiversity and conservation', sortOrder: 3),
        SeedTopic(title: 'Cladistics', sortOrder: 4),
      ]),
      SeedTopic(title: 'Human Physiology', sortOrder: 6, subtopics: [
        SeedTopic(title: 'Digestion and absorption', sortOrder: 1),
        SeedTopic(title: 'The blood system', sortOrder: 2),
        SeedTopic(title: 'Defence against infectious disease', sortOrder: 3),
        SeedTopic(title: 'Gas exchange', sortOrder: 4),
        SeedTopic(title: 'Nerves and muscles', sortOrder: 5),
        SeedTopic(title: 'Hormones and homeostasis', sortOrder: 6),
      ]),
    ],
  ),
  CurriculumSeedEntry(
    curriculumName: 'IB Physics',
    topics: [
      SeedTopic(title: 'Measurements & Uncertainties', sortOrder: 1, subtopics: [
        SeedTopic(title: 'Measurements in physics', sortOrder: 1),
        SeedTopic(title: 'Uncertainties and errors', sortOrder: 2),
        SeedTopic(title: 'Vectors and scalars', sortOrder: 3),
      ]),
      SeedTopic(title: 'Mechanics', sortOrder: 2, subtopics: [
        SeedTopic(title: 'Motion', sortOrder: 1),
        SeedTopic(title: 'Forces', sortOrder: 2),
        SeedTopic(title: 'Work, energy, and power', sortOrder: 3),
        SeedTopic(title: 'Momentum and impulse', sortOrder: 4),
      ]),
      SeedTopic(title: 'Thermal Physics', sortOrder: 3, subtopics: [
        SeedTopic(title: 'Thermal concepts', sortOrder: 1),
        SeedTopic(title: 'Modelling a gas', sortOrder: 2),
      ]),
      SeedTopic(title: 'Oscillations & Waves', sortOrder: 4, subtopics: [
        SeedTopic(title: 'Oscillations', sortOrder: 1),
        SeedTopic(title: 'Travelling waves', sortOrder: 2),
        SeedTopic(title: 'Wave characteristics', sortOrder: 3),
        SeedTopic(title: 'Wave behaviour', sortOrder: 4),
        SeedTopic(title: 'Standing waves', sortOrder: 5),
      ]),
      SeedTopic(title: 'Electricity & Magnetism', sortOrder: 5, subtopics: [
        SeedTopic(title: 'Electric fields', sortOrder: 1),
        SeedTopic(title: 'Heating effect of electric currents', sortOrder: 2),
        SeedTopic(title: 'Electric cells', sortOrder: 3),
        SeedTopic(title: 'Magnetic effects of electric currents', sortOrder: 4),
      ]),
      SeedTopic(title: 'Circular Motion & Gravitation', sortOrder: 6, subtopics: [
        SeedTopic(title: 'Circular motion', sortOrder: 1),
        SeedTopic(title: 'Newton\'s law of gravitation', sortOrder: 2),
      ]),
      SeedTopic(title: 'Atomic, Nuclear & Particle Physics', sortOrder: 7, subtopics: [
        SeedTopic(title: 'Discrete energy and radioactivity', sortOrder: 1),
        SeedTopic(title: 'Nuclear reactions', sortOrder: 2),
        SeedTopic(title: 'The structure of matter', sortOrder: 3),
      ]),
      SeedTopic(title: 'Energy Production', sortOrder: 8, subtopics: [
        SeedTopic(title: 'Energy sources', sortOrder: 1),
        SeedTopic(title: 'Thermal energy transfer', sortOrder: 2),
      ]),
    ],
  ),
  CurriculumSeedEntry(
    curriculumName: 'IB Mathematics: Analysis & Approaches',
    topics: [
      SeedTopic(title: 'Number & Algebra', sortOrder: 1, subtopics: [
        SeedTopic(title: 'Sequences and series', sortOrder: 1),
        SeedTopic(title: 'Exponents and logarithms', sortOrder: 2),
        SeedTopic(title: 'Binomial theorem', sortOrder: 3),
        SeedTopic(title: 'Complex numbers', sortOrder: 4),
      ]),
      SeedTopic(title: 'Functions', sortOrder: 2, subtopics: [
        SeedTopic(title: 'Linear and quadratic functions', sortOrder: 1),
        SeedTopic(title: 'Rational and exponential functions', sortOrder: 2),
        SeedTopic(title: 'Transformations of graphs', sortOrder: 3),
        SeedTopic(title: 'Polynomial and rational functions', sortOrder: 4),
      ]),
      SeedTopic(title: 'Geometry & Trigonometry', sortOrder: 3, subtopics: [
        SeedTopic(title: 'Right-angled trigonometry', sortOrder: 1),
        SeedTopic(title: 'Circular functions', sortOrder: 2),
        SeedTopic(title: 'Trigonometric equations and identities', sortOrder: 3),
        SeedTopic(title: 'Vectors', sortOrder: 4),
      ]),
      SeedTopic(title: 'Statistics & Probability', sortOrder: 4, subtopics: [
        SeedTopic(title: 'Descriptive statistics', sortOrder: 1),
        SeedTopic(title: 'Probability', sortOrder: 2),
        SeedTopic(title: 'Probability distributions', sortOrder: 3),
        SeedTopic(title: 'Hypothesis testing', sortOrder: 4),
      ]),
      SeedTopic(title: 'Calculus', sortOrder: 5, subtopics: [
        SeedTopic(title: 'Limits and derivatives', sortOrder: 1),
        SeedTopic(title: 'Integration', sortOrder: 2),
        SeedTopic(title: 'Differential equations', sortOrder: 3),
        SeedTopic(title: 'Series and Maclaurin expansions', sortOrder: 4),
      ]),
    ],
  ),
  CurriculumSeedEntry(
    curriculumName: 'A-Level Chemistry',
    topics: [
      SeedTopic(title: 'Atomic Structure', sortOrder: 1, subtopics: [
        SeedTopic(title: 'Fundamental particles', sortOrder: 1),
        SeedTopic(title: 'Mass number and isotopes', sortOrder: 2),
        SeedTopic(title: 'Electron configuration', sortOrder: 3),
      ]),
      SeedTopic(title: 'Bonding & Structure', sortOrder: 2, subtopics: [
        SeedTopic(title: 'Ionic bonding', sortOrder: 1),
        SeedTopic(title: 'Covalent bonding', sortOrder: 2),
        SeedTopic(title: 'Metallic bonding', sortOrder: 3),
        SeedTopic(title: 'Shapes of molecules', sortOrder: 4),
        SeedTopic(title: 'Intermolecular forces', sortOrder: 5),
      ]),
      SeedTopic(title: 'Redox Reactions', sortOrder: 3, subtopics: [
        SeedTopic(title: 'Oxidation numbers', sortOrder: 1),
        SeedTopic(title: 'Redox equations', sortOrder: 2),
      ]),
      SeedTopic(title: 'Inorganic Chemistry', sortOrder: 4, subtopics: [
        SeedTopic(title: 'Periodicity', sortOrder: 1),
        SeedTopic(title: 'Group 2 elements', sortOrder: 2),
        SeedTopic(title: 'Group 7 elements', sortOrder: 3),
      ]),
      SeedTopic(title: 'Organic Chemistry', sortOrder: 5, subtopics: [
        SeedTopic(title: 'Alkanes', sortOrder: 1),
        SeedTopic(title: 'Alkenes', sortOrder: 2),
        SeedTopic(title: 'Alcohols', sortOrder: 3),
        SeedTopic(title: 'Halogenoalkanes', sortOrder: 4),
        SeedTopic(title: 'Organic synthesis', sortOrder: 5),
      ]),
      SeedTopic(title: 'Energetics', sortOrder: 6, subtopics: [
        SeedTopic(title: 'Enthalpy changes', sortOrder: 1),
        SeedTopic(title: 'Calorimetry', sortOrder: 2),
        SeedTopic(title: 'Hess\'s law', sortOrder: 3),
        SeedTopic(title: 'Bond enthalpies', sortOrder: 4),
      ]),
      SeedTopic(title: 'Kinetics', sortOrder: 7, subtopics: [
        SeedTopic(title: 'Rates of reaction', sortOrder: 1),
        SeedTopic(title: 'Rate equations', sortOrder: 2),
        SeedTopic(title: 'Activation energy', sortOrder: 3),
      ]),
      SeedTopic(title: 'Equilibria', sortOrder: 8, subtopics: [
        SeedTopic(title: 'Dynamic equilibrium', sortOrder: 1),
        SeedTopic(title: 'Equilibrium constant Kc', sortOrder: 2),
        SeedTopic(title: 'Le Chatelier\'s principle', sortOrder: 3),
      ]),
    ],
  ),
  CurriculumSeedEntry(
    curriculumName: 'A-Level Biology',
    topics: [
      SeedTopic(title: 'Biological Molecules', sortOrder: 1, subtopics: [
        SeedTopic(title: 'Carbohydrates', sortOrder: 1),
        SeedTopic(title: 'Lipids', sortOrder: 2),
        SeedTopic(title: 'Proteins', sortOrder: 3),
        SeedTopic(title: 'Nucleic acids', sortOrder: 4),
      ]),
      SeedTopic(title: 'Cells', sortOrder: 2, subtopics: [
        SeedTopic(title: 'Cell structure', sortOrder: 1),
        SeedTopic(title: 'Cell division', sortOrder: 2),
        SeedTopic(title: 'Cell membranes', sortOrder: 3),
        SeedTopic(title: 'Cell transport', sortOrder: 4),
      ]),
      SeedTopic(title: 'Exchange & Transport', sortOrder: 3, subtopics: [
        SeedTopic(title: 'Gas exchange', sortOrder: 1),
        SeedTopic(title: 'Circulatory system', sortOrder: 2),
        SeedTopic(title: 'Digestion', sortOrder: 3),
      ]),
      SeedTopic(title: 'Genetics & Evolution', sortOrder: 4, subtopics: [
        SeedTopic(title: 'DNA and protein synthesis', sortOrder: 1),
        SeedTopic(title: 'Genetic diversity', sortOrder: 2),
        SeedTopic(title: 'Natural selection', sortOrder: 3),
      ]),
      SeedTopic(title: 'Ecology', sortOrder: 5, subtopics: [
        SeedTopic(title: 'Ecosystems', sortOrder: 1),
        SeedTopic(title: 'Energy transfer', sortOrder: 2),
        SeedTopic(title: 'Nutrient cycles', sortOrder: 3),
      ]),
    ],
  ),
  CurriculumSeedEntry(
    curriculumName: 'AP Chemistry',
    topics: [
      SeedTopic(title: 'Atomic Structure & Properties', sortOrder: 1, subtopics: [
        SeedTopic(title: 'Moles and molar mass', sortOrder: 1),
        SeedTopic(title: 'Mass spectrometry', sortOrder: 2),
        SeedTopic(title: 'Electron configuration', sortOrder: 3),
        SeedTopic(title: 'Periodic trends', sortOrder: 4),
      ]),
      SeedTopic(title: 'Molecular & Ionic Compound Structure', sortOrder: 2, subtopics: [
        SeedTopic(title: 'Types of bonds', sortOrder: 1),
        SeedTopic(title: 'Lewis structures', sortOrder: 2),
        SeedTopic(title: 'VSEPR theory', sortOrder: 3),
        SeedTopic(title: 'Molecular polarity', sortOrder: 4),
      ]),
      SeedTopic(title: 'Intermolecular Forces & Properties', sortOrder: 3, subtopics: [
        SeedTopic(title: 'Intermolecular forces', sortOrder: 1),
        SeedTopic(title: 'Properties of solids', sortOrder: 2),
        SeedTopic(title: 'Gas laws', sortOrder: 3),
        SeedTopic(title: 'Solutions and mixtures', sortOrder: 4),
      ]),
      SeedTopic(title: 'Chemical Reactions', sortOrder: 4, subtopics: [
        SeedTopic(title: 'Chemical equations', sortOrder: 1),
        SeedTopic(title: 'Stoichiometry', sortOrder: 2),
        SeedTopic(title: 'Neutralisation reactions', sortOrder: 3),
        SeedTopic(title: 'Redox reactions', sortOrder: 4),
      ]),
      SeedTopic(title: 'Kinetics', sortOrder: 5, subtopics: [
        SeedTopic(title: 'Reaction rates', sortOrder: 1),
        SeedTopic(title: 'Rate laws', sortOrder: 2),
        SeedTopic(title: 'Activation energy', sortOrder: 3),
      ]),
      SeedTopic(title: 'Thermodynamics', sortOrder: 6, subtopics: [
        SeedTopic(title: 'Endothermic and exothermic', sortOrder: 1),
        SeedTopic(title: 'Enthalpy', sortOrder: 2),
        SeedTopic(title: 'Gibbs free energy', sortOrder: 3),
      ]),
      SeedTopic(title: 'Equilibrium', sortOrder: 7, subtopics: [
        SeedTopic(title: 'Equilibrium constant', sortOrder: 1),
        SeedTopic(title: 'Le Chatelier\'s principle', sortOrder: 2),
        SeedTopic(title: 'pH and pKa', sortOrder: 3),
      ]),
      SeedTopic(title: 'Acids & Bases', sortOrder: 8, subtopics: [
        SeedTopic(title: 'Acid-base theories', sortOrder: 1),
        SeedTopic(title: 'Buffer solutions', sortOrder: 2),
        SeedTopic(title: 'Titration curves', sortOrder: 3),
      ]),
      SeedTopic(title: 'Electrochemistry', sortOrder: 9, subtopics: [
        SeedTopic(title: 'Galvanic cells', sortOrder: 1),
        SeedTopic(title: 'Standard reduction potentials', sortOrder: 2),
        SeedTopic(title: 'Electrolysis', sortOrder: 3),
      ]),
    ],
  ),
];

CurriculumSeedEntry? findSeedEntry(String curriculumName) {
  for (final entry in curriculumSeedData) {
    if (AnswerComparator.areEquivalent(entry.curriculumName, curriculumName)) {
      return entry;
    }
  }
  return null;
}
