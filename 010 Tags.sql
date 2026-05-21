USE StackOverflow2013;
GO

DROP TABLE IF EXISTS dbo.Tags;
CREATE TABLE dbo.Tags
(
    Id INT IDENTITY(1, 1),
    Tag VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Tags_Id
        PRIMARY KEY (Id)
);
GO

DROP INDEX IF EXISTS IDX_Tags_Id ON dbo.Tags;
CREATE UNIQUE NONCLUSTERED INDEX IDX_Tags_Tag ON dbo.Tags (Tag);
GO

/*
    Procedure: dbo.LoadTagValues
    
    Purpose:
        Extracts unique tags from dbo.Posts where AnswerCount > 0
        and loads them into dbo.Tags, avoiding duplicates.
    
    Parameters:
        None
    
    Returns:
        TagsInserted INT - Number of new tags inserted
    
    Author:     turkaffe
    Created:    2026-05-07
    Modified:   
    
    Example:
        EXEC dbo.LoadTagValues;
*/
CREATE OR ALTER PROCEDURE dbo.LoadTagValues
AS
BEGIN
    SET NOCOUNT ON;
    CREATE TABLE #tags
    (
        Tag VARCHAR(50) NOT NULL
    );

    INSERT INTO #tags
    (
        Tag
    )
    SELECT DISTINCT
           TRIM(REPLACE(x.value, '>', ''))
    FROM dbo.Posts p
        CROSS APPLY STRING_SPLIT(p.Tags, '<') x
    WHERE p.AnswerCount > 0
          AND x.value > ''
          AND p.Tags IS NOT NULL;

    INSERT INTO dbo.Tags
    (
        Tag
    )
    SELECT t1.Tag
    FROM #tags t1
    WHERE NOT EXISTS
    (
        SELECT * FROM dbo.Tags t2 WHERE t2.Tag = t1.Tag
    );

    SELECT @@ROWCOUNT AS TagsInserted;
END;
GO 


/*
    Procedure: dbo.GetTagsByString
    
    Purpose:
        Retrieves tags from dbo.Tags matching provided search criteria
        using fuzzy matching via Levenshtein distance.
    
    Parameters:
        @SearchTags VARCHAR(500)  - Comma-separated tag search terms
        @ExactMatchOnly BIT       - 1 = exact match only, 0 = fuzzy match (default: 1)
        @Sensitivity INT          - Levenshtein distance threshold (default: 4)
    
    Returns:
        Id INT - Matching tag Id
    
    Author:     turkaffe
    Created:    2026-05-07
    Modified:   20260521 - slight preformance gains
    
    Example:
        EXEC dbo.GetTagsByString @SearchTags = 'python, c#', @ExactMatchOnly = 0, @Sensitivity = 3;
*/
CREATE OR ALTER PROCEDURE dbo.GetTagsByString
(
    @SearchTags VARCHAR(500),
    @ExactMatchOnly BIT = 1,
    @Sensitivity INT = 4
)
AS
BEGIN
    SET NOCOUNT ON;
    IF (@SearchTags IS NULL OR @SearchTags = '')
    BEGIN
        RAISERROR('No Search Tag(s) provided', 16, 1);
        RETURN (0);
    END;
    
    CREATE TABLE #search( tag VARCHAR(50) NOT NULL);
    CREATE CLUSTERED INDEX cx_tempsearch ON #search (tag);

    INSERT INTO #search(tag)
    SELECT TRIM(value) tag
    FROM STRING_SPLIT(@SearchTags, ',');

    CREATE TABLE #tags
    (
        Id INT NOT NULL,
        Tag VARCHAR(50) NOT NULL,
        MatchScore INT NULL
    );
    
    CREATE CLUSTERED INDEX cx_temptags ON #tags (Tag);

    INSERT INTO #tags
    (
        Id,
        Tag
    )
    SELECT t.Id,
           t.Tag
    FROM dbo.Tags t
    JOIN #search s
        ON  t.tag LIKE s.tag + '%'
    WHERE 1=1;

    WITH ScoredTags
    AS (SELECT t.Id,
               dbo.Levenshtein(t.Tag, x.tag, @Sensitivity) AS MatchScore
        FROM #tags t
            CROSS APPLY
        (SELECT * FROM #search s) x )
    SELECT st.Id
    FROM ScoredTags st
    WHERE (
              @ExactMatchOnly = 1
              AND st.MatchScore = 0
          )
          OR
          (
              @ExactMatchOnly = 0
              AND st.MatchScore <= @Sensitivity
          );
END;
GO