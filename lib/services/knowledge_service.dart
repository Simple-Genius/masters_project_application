import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class KnowledgeService {
  static const String knowledgeBasePath = 'assets/knowledge/uk_seasonal_worker_knowledge.txt';
  
  List<KnowledgeSection> _sections = [];
  bool _isInitialized = false;

  Future<bool> initialize() async {
    try {
      debugPrint('Loading UK Seasonal Worker knowledge base...');
      final content = await rootBundle.loadString(knowledgeBasePath);
      
      _sections = _parseKnowledgeBase(content);
      _isInitialized = true;
      
      debugPrint('Knowledge base loaded: ${_sections.length} sections');
      return true;
    } catch (e) {
      debugPrint('Error loading knowledge base: $e');
      return false;
    }
  }

  List<KnowledgeSection> _parseKnowledgeBase(String content) {
    final sections = <KnowledgeSection>[];
    final parts = content.split('----------');
    
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) continue;
      
      final lines = part.split('\n');
      final title = lines.isNotEmpty ? lines[0].trim() : 'Section ${i + 1}';
      final text = lines.skip(1).join('\n').trim();
      
      if (text.isNotEmpty) {
        sections.add(KnowledgeSection(
          id: 'section_${i + 1}',
          title: title,
          content: text,
          keywords: _extractKeywords('$title $text'),
        ));
      }
    }
    
    return sections;
  }

  List<String> _extractKeywords(String text) {
    final keywords = <String>{};
    final cleanText = text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    
    final words = cleanText.split(' ');
    
    // Add important keywords
    for (final word in words) {
      if (word.length > 3 && !_isStopWord(word)) {
        keywords.add(word);
      }
    }
    
    // Add specific seasonal worker terms
    final specialTerms = [
      'visa', 'work permit', 'seasonal worker', 'scheme operator',
      'agri-hr', 'concordia', 'fruitful jobs', 'hops labour', 'pro-force',
      'accommodation', 'pay', 'wage', 'salary', 'working conditions',
      'help', 'support', 'contact', 'emergency', 'rights', 'legal',
      'application', 'recruitment', 'agent', 'scam', 'fraud'
    ];
    
    for (final term in specialTerms) {
      if (text.toLowerCase().contains(term)) {
        keywords.add(term);
      }
    }
    
    return keywords.toList();
  }

  bool _isStopWord(String word) {
    const stopWords = {
      'the', 'and', 'you', 'are', 'for', 'that', 'will', 'with', 'have',
      'this', 'can', 'may', 'not', 'but', 'they', 'your', 'any', 'all',
      'about', 'also', 'from', 'been', 'when', 'what', 'where', 'how'
    };
    return stopWords.contains(word);
  }

  List<KnowledgeSection> searchRelevantSections(String query, {int maxResults = 3}) {
    if (!_isInitialized) {
      debugPrint('Knowledge base not initialized');
      return [];
    }

    final queryWords = query.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((word) => word.length > 2 && !_isStopWord(word))
        .toList();

    if (queryWords.isEmpty) return [];

    final scoredSections = <ScoredSection>[];

    for (final section in _sections) {
      double score = 0.0;
      
      // Score based on title match
      for (final queryWord in queryWords) {
        if (section.title.toLowerCase().contains(queryWord)) {
          score += 3.0; // Higher weight for title matches
        }
      }
      
      // Score based on content match
      for (final queryWord in queryWords) {
        final contentLower = section.content.toLowerCase();
        final matches = queryWord.allMatches(contentLower).length;
        score += matches * 1.0;
      }
      
      // Score based on keyword match
      for (final queryWord in queryWords) {
        for (final keyword in section.keywords) {
          if (keyword.contains(queryWord) || queryWord.contains(keyword)) {
            score += 2.0;
          }
        }
      }
      
      if (score > 0) {
        scoredSections.add(ScoredSection(section, score));
      }
    }

    // Sort by score and return top results
    scoredSections.sort((a, b) => b.score.compareTo(a.score));
    return scoredSections
        .take(maxResults)
        .map((scored) => scored.section)
        .toList();
  }

  String generateContextualResponse(String query) {
    final relevantSections = searchRelevantSections(query);
    
    if (relevantSections.isEmpty) {
      // Check if query is related to seasonal work at all
      if (!_isSeasonalWorkRelated(query)) {
        return ''; // Return empty string to trigger Core ML
      }
      return _getDefaultResponse(query);
    }

    final contextBuilder = StringBuffer();
    contextBuilder.writeln('Based on the UK Seasonal Worker information:\n');
    
    for (int i = 0; i < relevantSections.length; i++) {
      final section = relevantSections[i];
      contextBuilder.writeln('${section.title}:');
      contextBuilder.writeln(section.content);
      if (i < relevantSections.length - 1) {
        contextBuilder.writeln();
      }
    }
    
    return contextBuilder.toString();
  }

  String _getDefaultResponse(String query) {
    final queryLower = query.toLowerCase();
    
    if (queryLower.contains('operator') || queryLower.contains('company')) {
      return '''
The five approved Seasonal Worker Scheme operators are:
• AGRI-hr (https://www.agri-hr.com)
• Concordia (UK) Ltd (https://www.concordia.org.uk/seasonal-work)
• Fruitful Jobs (https://www.fruitfuljobs.com/seasonal-worker-scheme)
• HOPS Labour Solutions Ltd (https://www.hopslaboursolutions.com/sws)
• Pro-Force Limited (https://www.pro-force.co.uk/support/visa-information)

Only these companies can legally provide seasonal worker visas for the UK.
''';
    }
    
    if (queryLower.contains('help') || queryLower.contains('support')) {
      return '''
Help contacts for seasonal workers:
• Work Rights Centre (England & Wales): 0300 400 100
• Worker Support Centre (Scotland): 0800 0581 633
• Modern Slavery Helpline: 08000 121 700
• Emergency: 999

All advice is free and confidential.
''';
    }
    
    return '''
I can help you with information about UK seasonal work including:
• Visa applications and scheme operators
• Working conditions and rights
• Accommodation and pay
• Getting help and support

What specific aspect would you like to know about?
''';
  }

  bool _isSeasonalWorkRelated(String query) {
    final queryLower = query.toLowerCase();
    final seasonalWorkKeywords = [
      'seasonal worker', 'seasonal work', 'visa', 'work permit', 'scheme operator',
      'agri-hr', 'concordia', 'fruitful jobs', 'hops labour', 'pro-force',
      'accommodation', 'farm work', 'agriculture', 'harvest',
      'uk seasonal', 'seasonal scheme'
    ];
    
    // Use more specific matching - require exact phrase or word boundaries
    return seasonalWorkKeywords.any((keyword) {
      if (keyword.contains(' ')) {
        // Multi-word phrases need exact match
        return queryLower.contains(keyword);
      } else {
        // Single words need word boundaries
        return RegExp(r'\b' + RegExp.escape(keyword) + r'\b').hasMatch(queryLower);
      }
    });
  }

  bool get isInitialized => _isInitialized;
  int get sectionsCount => _sections.length;
}

class KnowledgeSection {
  final String id;
  final String title;
  final String content;
  final List<String> keywords;

  KnowledgeSection({
    required this.id,
    required this.title,
    required this.content,
    required this.keywords,
  });
}

class ScoredSection {
  final KnowledgeSection section;
  final double score;

  ScoredSection(this.section, this.score);
}