/* QtLua -- Lua bindings for Qt
   Copyright (C) 2011, Jarek Pelczar

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General
   Public License along with this library; if not, write to the
   Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301 USA

*/

#ifndef QLUASYNTAXHIGHLIGHTER_P_H
#define QLUASYNTAXHIGHLIGHTER_P_H

#include <QSyntaxHighlighter>
#include <QTextCharFormat>
#include <QRegExp>
#include <QVector>

class QLuaSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT
public:
    explicit QLuaSyntaxHighlighter(QTextDocument *document = 0);
    ~QLuaSyntaxHighlighter();

protected:
    void highlightBlock(const QString &text);

    struct HighlightingRule
    {
        QRegExp pattern;
        QTextCharFormat format;
    };
    QVector<HighlightingRule> highlightingRules;

    QRegExp commentStartExpression;
    QRegExp commentEndExpression;

    QTextCharFormat keywordFormat;    
    QTextCharFormat singleLineCommentFormat;
    QTextCharFormat multiLineCommentFormat;
    QTextCharFormat quotationFormat;
    QTextCharFormat functionFormat;
	QTextCharFormat operatorFormat;
	QTextCharFormat numberFormat;
	QTextCharFormat identifierFormat;
};

#endif // QLUASYNTAXHIGHLIGHTER_P_H
