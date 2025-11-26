import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../bottom_nav.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({Key? key}) : super(key: key);

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  // サブスク状態（テスト用）
  bool isSubscribed = false; // falseでサブスク未登録をテスト
  
  // フィルター・並び替え
  List<String> selectedLanguages = ['すべて']; // 複数選択可能
  String sortOrder = '新しい順'; // 新しい順、古い順（サブスクのみ）
  bool showJapaneseOnFront = true; // true: 日本語を表面に、false: 外国語を表面に
  List<String> selectedFilters = []; // お気に入り、学習済みなどのフィルター
  
  // 仮データ（例文付き）
  List<VocabularyCard> vocabularies = List.generate(100, (index) {
    return VocabularyCard(
      id: 'vocab_$index',
      japanese: '日本語 ${index + 1}',
      foreign: 'Word ${index + 1}',
      language: index % 4 == 0 ? '日本語' : (index % 4 == 1 ? '英語' : (index % 4 == 2 ? '中国語' : '韓国語')),
      exampleSentence: 'This is an example sentence ${index + 1}.',
      exampleTranslation: 'これは例文 ${index + 1} です。',
      isFlagged: false,
      isLearned: false,
      createdAt: DateTime.now().subtract(Duration(days: index)),
    );
  });

  List<VocabularyCard> get filteredVocabularies {
    var filtered = vocabularies.where((v) {
      // 言語フィルター
      if (!selectedLanguages.contains('すべて')) {
        if (!selectedLanguages.contains(v.language)) {
          return false;
        }
      }
      
      // お気に入り・学習済みフィルター
      if (selectedFilters.isNotEmpty) {
        bool matchesFilter = false;
        
        // いずれかのフィルターに一致すればOK
        if (selectedFilters.contains('お気に入り') && v.isFlagged) {
          matchesFilter = true;
        }
        if (selectedFilters.contains('学習済み') && v.isLearned) {
          matchesFilter = true;
        }
        if (selectedFilters.contains('未登録') && !v.isFlagged && !v.isLearned) {
          matchesFilter = true;
        }
        
        if (!matchesFilter) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // 並び替え
    if (sortOrder == '新しい順') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (sortOrder == '古い順' && isSubscribed) {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    return filtered;
  }
  
  // 学習済みの単語があるかチェック
  bool get hasLearnedVocabs {
    return vocabularies.any((v) => v.isLearned);
  }

  @override
  Widget build(BuildContext context) {
    final displayList = filteredVocabularies;
    final freeLimit = 50; // 無料で見られる件数

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '単語帳',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // フィルター・並び替えエリア
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterButton(
                        label: '言語',
                        value: selectedLanguages.contains('すべて') 
                            ? 'すべて' 
                            : selectedLanguages.join(', '),
                        onTap: () => _showLanguageFilter(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterButton(
                        label: '並び替え',
                        value: sortOrder,
                        onTap: () => _showSortFilter(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterButton(
                        label: 'フィルター',
                        value: selectedFilters.isEmpty 
                            ? 'すべて' 
                            : selectedFilters.join(', '),
                        onTap: () => _showStatusFilter(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      '表面表示:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('日本語')),
                          ButtonSegment(value: false, label: Text('外国語')),
                        ],
                        selected: {showJapaneseOnFront},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            showJapaneseOnFront = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 単語リスト
          Expanded(
            child: displayList.isEmpty && selectedFilters.contains('学習済み') && !hasLearnedVocabs
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'まだ学習登録されていません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '単語を左にスワイプして学習済みにしましょう',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : displayList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '該当する単語がありません',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final vocab = displayList[index];
                          final isLocked = !isSubscribed && index >= freeLimit;
                          
                          return _FlipCard(
                            key: ValueKey(vocab.id),
                            vocab: vocab,
                            isLocked: isLocked,
                            showJapaneseOnFront: showJapaneseOnFront,
                            onTap: () {
                              if (isLocked) {
                                _showSubscriptionDialog();
                              } else {
                                _navigateToDetail(vocab);
                              }
                            },
                            onFlagToggle: () {
                              setState(() {
                                final vocabIndex = vocabularies.indexWhere((v) => v.id == vocab.id);
                                if (vocabIndex != -1) {
                                  vocabularies[vocabIndex].isFlagged = !vocabularies[vocabIndex].isFlagged;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(vocabularies[vocabIndex].isFlagged 
                                          ? 'お気に入り登録しました' 
                                          : 'お気に入り解除しました'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              });
                            },
                            onLearnedToggle: () {
                              final vocabIndex = vocabularies.indexWhere((v) => v.id == vocab.id);
                              if (vocabIndex != -1) {
                                setState(() {
                                  vocabularies[vocabIndex].isLearned = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('学習済みフォルダに移動しました'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            isUnregisteredFilterActive: selectedFilters.contains('未登録'),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // TODO: 画面遷移処理
        },
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
          ],
        ),
      ),
    );
  }

  void _showLanguageFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '言語を選択（複数選択可）',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedLanguages = List.from(selectedLanguages);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('完了'),
                        ),
                      ],
                    ),
                  ),
                  ...['すべて', '日本語', '英語', '中国語', '韓国語'].map((lang) {
                    final isSelected = selectedLanguages.contains(lang);
                    return CheckboxListTile(
                      title: Text(lang),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (lang == 'すべて') {
                            if (value == true) {
                              selectedLanguages = ['すべて'];
                            } else {
                              selectedLanguages = [];
                            }
                          } else {
                            if (value == true) {
                              selectedLanguages.remove('すべて');
                              selectedLanguages.add(lang);
                            } else {
                              selectedLanguages.remove(lang);
                              if (selectedLanguages.isEmpty) {
                                selectedLanguages = ['すべて'];
                              }
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '並び替え',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                title: const Text('新しい順'),
                trailing: sortOrder == '新しい順'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() {
                    sortOrder = '新しい順';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    const Text('古い順'),
                    if (!isSubscribed) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                    ],
                  ],
                ),
                trailing: sortOrder == '古い順'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  if (isSubscribed) {
                    setState(() {
                      sortOrder = '古い順';
                    });
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                    _showSubscriptionDialog();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'フィルター（複数選択可）',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilters = List.from(selectedFilters);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('完了'),
                        ),
                      ],
                    ),
                  ),
                  // お気に入り
                  CheckboxListTile(
                    title: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600], size: 20),
                        const SizedBox(width: 8),
                        const Text('お気に入り'),
                      ],
                    ),
                    value: selectedFilters.contains('お気に入り'),
                    onChanged: (bool? value) {
                      setModalState(() {
                        if (value == true) {
                          selectedFilters.add('お気に入り');
                        } else {
                          selectedFilters.remove('お気に入り');
                        }
                      });
                    },
                  ),
                  // 学習済み（常に表示、常に選択可能）
                  CheckboxListTile(
                    title: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[400], size: 20),
                        const SizedBox(width: 8),
                        const Text('学習済み'),
                      ],
                    ),
                    value: selectedFilters.contains('学習済み'),
                    onChanged: (bool? value) {
                      setModalState(() {
                        if (value == true) {
                          selectedFilters.add('学習済み');
                        } else {
                          selectedFilters.remove('学習済み');
                        }
                      });
                    },
                  ),
                  // 未登録
                  CheckboxListTile(
                    title: Row(
                      children: [
                        Icon(Icons.star_border, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 8),
                        const Text('未登録'),
                      ],
                    ),
                    value: selectedFilters.contains('未登録'),
                    onChanged: (bool? value) {
                      setModalState(() {
                        if (value == true) {
                          selectedFilters.add('未登録');
                        } else {
                          selectedFilters.remove('未登録');
                        }
                      });
                    },
                  ),
                  if (selectedFilters.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              selectedFilters.clear();
                            });
                          },
                          child: const Text('クリア'),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToDetail(VocabularyCard vocab) {
    // 単語詳細画面へ遷移
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${vocab.japanese}の詳細画面へ（未実装）'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'サブスク登録',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'この機能を利用するにはサブスク登録が必要です。\n\n・51件目以降の単語閲覧\n・古い順での並び替え\n・その他プレミアム機能',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // サブスク登録画面へ遷移
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('サブスク登録画面へ（未実装）'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('登録する'),
            ),
          ],
        );
      },
    );
  }
}

// フリップカードウィジェット
class _FlipCard extends StatefulWidget {
  final VocabularyCard vocab;
  final bool isLocked;
  final bool showJapaneseOnFront;
  final VoidCallback onTap;
  final VoidCallback onFlagToggle;
  final VoidCallback onLearnedToggle;
  final bool isUnregisteredFilterActive;

  const _FlipCard({
    Key? key,
    required this.vocab,
    required this.isLocked,
    required this.showJapaneseOnFront,
    required this.onTap,
    required this.onFlagToggle,
    required this.onLearnedToggle,
    required this.isUnregisteredFilterActive,
  }) : super(key: key);

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.vocab.id),
      background: _buildSwipeBackground(
        color: Colors.amber,
        icon: Icons.star,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: Colors.green,
        icon: Icons.check,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 右へスワイプ: お気に入り登録/解除
          widget.onFlagToggle();
          return false; // カードは削除しない
        } else if (direction == DismissDirection.endToStart) {
          // 左へスワイプ: 学習済みにする
          if (!widget.vocab.isLearned) {
            widget.onLearnedToggle();
            // 未登録フィルターが有効な場合は、リストから削除
            return widget.isUnregisteredFilterActive;
          }
          return false; // すでに学習済みの場合は何もしない
        }
        return false;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPressStart: widget.isLocked ? null : (_) {
          if (!_isFlipped) {
            _controller.forward();
            setState(() {
              _isFlipped = true;
            });
          }
        },
        onLongPressEnd: widget.isLocked ? null : (_) {
          if (_isFlipped) {
            _controller.reverse();
            setState(() {
              _isFlipped = false;
            });
          }
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * math.pi;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: angle >= math.pi / 2
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: _buildBackSide(),
                    )
                  : _buildFrontSide(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.vocab.isFlagged)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.star, color: Colors.amber[600], size: 20),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.vocab.language,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.purple[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.vocab.isLearned)
                Icon(Icons.check_circle, color: Colors.green[400], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.showJapaneseOnFront ? widget.vocab.japanese : widget.vocab.foreign,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.vocab.isFlagged)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.star, color: Colors.amber[600], size: 20),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.vocab.language,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.purple[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.vocab.isLearned)
                Icon(Icons.check_circle, color: Colors.green[400], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.showJapaneseOnFront ? widget.vocab.foreign : widget.vocab.japanese,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.vocab.isFlagged ? Colors.amber[300]! : Colors.grey[300]!,
          width: widget.vocab.isFlagged ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          child,
          if (widget.isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock, color: Colors.white, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'サブスク登録で閲覧可能',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white, size: 32),
    );
  }
}

class VocabularyCard {
  final String id;
  final String japanese;
  final String foreign;
  final String language;
  final String exampleSentence;
  final String exampleTranslation;
  bool isFlagged;
  bool isLearned;
  final DateTime createdAt;

  VocabularyCard({
    required this.id,
    required this.japanese,
    required this.foreign,
    required this.language,
    required this.exampleSentence,
    required this.exampleTranslation,
    required this.isFlagged,
    required this.isLearned,
    required this.createdAt,
  });
}