//
// AKSegmentedControl.m
//
// Copyright (c) 2013 Ali Karagoz (http://alikaragoz.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AKSegmentedControl.h"

@interface AKSegmentedControl ()

@property (nonatomic, strong) NSMutableArray *separatorsArray;
@property (nonatomic, strong) UIImageView *backgroundImageView;

// Init
- (void)commonInitializer;

@end

@implementation AKSegmentedControl {
  BOOL _constrainsSetuped;
  NSMutableArray *_buttonsConstraints;
}

#pragma mark - Init and Dealloc

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    [self commonInitializer];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;
    
    [self commonInitializer];
    
    return self;
}

- (void)commonInitializer {
    _separatorsArray = [NSMutableArray array];
    self.selectedIndexes = [NSIndexSet indexSet];
    self.contentEdgeInsets = UIEdgeInsetsZero;
    self.segmentedControlMode = AKSegmentedControlModeSticky;
    self.buttonsArray = [[NSArray alloc] init];
    
    [self addSubview:self.backgroundImageView];
    [self setNeedsUpdateConstraints];
}

#pragma mark - Layout

- (void)updateConstraints
{
  if (!_constrainsSetuped) {
    NSDictionary *views = @{@"background": _backgroundImageView};
    _backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[background]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[background]|" options:0 metrics:nil views:views]];
    
    _constrainsSetuped = YES;
  }
  if (_buttonsConstraints) {
    [self removeConstraints:_buttonsConstraints];
    [_buttonsConstraints removeAllObjects];
  } else {
    _buttonsConstraints = [[NSMutableArray alloc] initWithCapacity:0];
  }
  if ([_buttonsArray count] > 0) {
    NSMutableString *horizontalFormat = [[NSMutableString alloc] init];
    NSMutableDictionary *views = [[NSMutableDictionary alloc] initWithCapacity:[_buttonsArray count] + [_separatorsArray count]];
    NSDictionary *metrics = @{@"TOP": @(_contentEdgeInsets.top),
                              @"LEFT": @(_contentEdgeInsets.left),
                              @"BOTTOM": @(_contentEdgeInsets.bottom),
                              @"RIGHT": @(_contentEdgeInsets.right),
                              @"SEPARATOR_WIDTH": @(_separatorImage.size.width)};
    [_buttonsArray enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
      button.translatesAutoresizingMaskIntoConstraints = NO;
      views[[NSString stringWithFormat:@"button%tu", idx]] = button;
      NSString *format = [NSString stringWithFormat:@"V:|-(TOP)-[button%tu]-(BOTTOM)-|", idx];
      [_buttonsConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:views]];
      if (idx == 0) {
        [horizontalFormat appendFormat:@"H:|-(LEFT)-[button%tu]", idx];
      } else {
        [horizontalFormat appendFormat:@"[separator%tu(==SEPARATOR_WIDTH)][button%tu(==button%tu)]", idx-1, idx, idx-1];
      }
    }];
    [_separatorsArray enumerateObjectsUsingBlock:^(UIImageView *obj, NSUInteger idx, BOOL *stop) {
      obj.translatesAutoresizingMaskIntoConstraints = NO;
      views[[NSString stringWithFormat:@"separator%tu", idx]] = obj;
      NSString *format = [NSString stringWithFormat:@"V:|-(TOP)-[separator%tu]-(BOTTOM)-|", idx];
      [_buttonsConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:views]];
    }];
    [horizontalFormat appendString:@"-(RIGHT)-|"];
    [_buttonsConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:horizontalFormat options:0 metrics:metrics views:views]];
    [self addConstraints:_buttonsConstraints];
  }
  [super updateConstraints];
}

#pragma mark - Button Actions

- (void)segmentButtonPressed:(id)sender {
    UIButton *button = (UIButton *)sender;
    
    if (![button isKindOfClass:UIButton.class]) {
        return;
    }
    
    NSUInteger selectedIndex = button.tag;
    NSIndexSet *set = _selectedIndexes;
    
    if (_segmentedControlMode == AKSegmentedControlModeMultipleSelectionable) {

        NSMutableIndexSet *mutableSet = [set mutableCopy];
        if ([_selectedIndexes containsIndex:selectedIndex]) {
            [mutableSet removeIndex:selectedIndex];
        }
        
        else {
            [mutableSet addIndex:selectedIndex];
        }
        
        [self setSelectedIndexes:[mutableSet copy]];
    }
    
    else {
        [self setSelectedIndex:selectedIndex];
    }
    
    BOOL willSendAction = (![_selectedIndexes isEqualToIndexSet:set] || _segmentedControlMode == AKSegmentedControlModeButton);
    
    if (willSendAction) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
}

#pragma mark - Setters

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    [_backgroundImageView setImage:_backgroundImage];
}

- (void)setButtonsArray:(NSArray *)buttonsArray {
    [_buttonsArray makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_separatorsArray removeAllObjects];
    
    _buttonsArray = buttonsArray;
    
    [_buttonsArray enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        [self addSubview:button];
        if (_segmentedControlMode == AKSegmentedControlModeSticky) {
            [button addTarget:self action:@selector(segmentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            button.exclusiveTouch = YES;
        } else {
            [button addTarget:self action:@selector(segmentButtonPressed:) forControlEvents:UIControlEventTouchDown];
        }
        [button setTag:idx];
    }];
    
    [self rebuildSeparators];
    [self updateButtons];
}

- (void)insertButton:(UIButton *)button atIndex:(NSUInteger)index
{
  //Insert button
  NSMutableArray *buttons = [_buttonsArray mutableCopy];
  [buttons insertObject:button atIndex:index];
  _buttonsArray = [buttons copy];
  [self addSubview:button];
  button.frame = CGRectMake(_contentEdgeInsets.left, _contentEdgeInsets.top, 0.0, CGRectGetHeight(self.bounds) - _contentEdgeInsets.top - _contentEdgeInsets.bottom);

  if (_segmentedControlMode == AKSegmentedControlModeSticky) {
    [button addTarget:self action:@selector(segmentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
  } else {
    [button addTarget:self action:@selector(segmentButtonPressed:) forControlEvents:UIControlEventTouchDown];
  }
  [_buttonsArray enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
    [button setTag:idx];
  }];
  NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
  [_selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    if (idx > index) {
      [set addIndex:++idx];
    } else {
      [set addIndex:idx];
    }
  }];
  _selectedIndexes = [set copy];
  
  //Insert separator
  UIImageView *separatorImageView = [[UIImageView alloc] initWithImage:_separatorImage];
  [self addSubview:separatorImageView];
  separatorImageView.frame = CGRectMake(_contentEdgeInsets.left, _contentEdgeInsets.top, _separatorImage.size.width, CGRectGetHeight(self.bounds) - _contentEdgeInsets.top - _contentEdgeInsets.bottom);
  [_separatorsArray insertObject:separatorImageView atIndex:index];
  
  [self setNeedsUpdateConstraints];
  [self updateButtons];
}

- (void)setSeparatorImage:(UIImage *)separatorImage {
    _separatorImage = separatorImage;
    [self rebuildSeparators];
}

- (void)setSegmentedControlMode:(AKSegmentedControlMode)segmentedControlMode {
    _segmentedControlMode = segmentedControlMode;
    [self updateButtons];
}

- (void)setSelectedIndex:(NSUInteger)index {
    _selectedIndexes = [NSIndexSet indexSetWithIndex:index];
    [self updateButtons];
}

- (void)setSelectedIndexes:(NSIndexSet *)indexSet byExpandingSelection:(BOOL)expandSelection {
    
    if (_segmentedControlMode != AKSegmentedControlModeMultipleSelectionable) {
        return;
    }
    
    if (!expandSelection) {
        _selectedIndexes = [NSIndexSet indexSet];
    }
    
    NSMutableIndexSet *mutableIndexSet = [_selectedIndexes mutableCopy];
    [mutableIndexSet addIndexes:indexSet];
    [self setSelectedIndexes:mutableIndexSet];
}

- (void)setSelectedIndexes:(NSIndexSet *)selectedIndexes {
    _selectedIndexes = [selectedIndexes copy];
    [self updateButtons];
}

#pragma mark - Rearranging

- (void)rebuildSeparators {
    [_separatorsArray makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSUInteger separatorsNumber = [_buttonsArray count] - 1;
    
    [_separatorsArray removeAllObjects];
    [_buttonsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx < separatorsNumber) {
            UIImageView *separatorImageView = [[UIImageView alloc] initWithImage:_separatorImage];
            [self addSubview:separatorImageView];
            [_separatorsArray addObject:separatorImageView];
        }
    }];
    [self setNeedsUpdateConstraints];
}

- (UIImageView *)backgroundImageView {
    if (_backgroundImageView == nil) {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    }
    
    return _backgroundImageView;
}

- (void)updateButtons {
    
    if ([_buttonsArray count] == 0) {
        return;
    }
    
    [_buttonsArray makeObjectsPerformSelector:@selector(setSelected:) withObject:nil];
    
    [_selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        if (_segmentedControlMode != AKSegmentedControlModeButton) {
            if (idx >= [_buttonsArray count]) return;
            
            UIButton *button = _buttonsArray[idx];
            button.selected = YES;
        }
    }];
}

@end
