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

DROP TABLE IF EXISTS dbo.PostTags;
CREATE TABLE dbo.PostTags
(
    PostId INT NOT NULL,
    TagId INT NOT NULL,
    CONSTRAINT PK_PostTags PRIMARY KEY (PostId, TagId),
    CONSTRAINT FK_PostTags_PostId FOREIGN KEY (PostId) REFERENCES dbo.Posts(Id),
    CONSTRAINT FK_PostTags_TagId FOREIGN KEY (TagId) REFERENCES dbo.Tags(Id)
);
GO

DROP INDEX IF EXISTS IX_PostTags_TagId ON dbo.PostTags;
CREATE INDEX IX_PostTags_TagId ON dbo.PostTags(TagId);
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
    Modified:   20260521 - added PostTags load
    
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
    
    INSERT INTO dbo.PostTags 
    (
        PostId,
        TagId
    )
    SELECT DISTINCT p.Id, 
        t.Id
    FROM dbo.Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '<') x
    JOIN dbo.Tags t ON t.Tag = TRIM(REPLACE(x.value, '>', ''))
    WHERE p.AnswerCount > 0
      AND x.value > ''
      AND p.Tags IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM dbo.PostTags pt WHERE pt.PostId = p.Id AND pt.TagId = t.Id);

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


/*
    Function: dbo.GetTagsByString
    
    Purpose:
        Retrieves tags from dbo.Tags matching provided search criteria
        using fuzzy matching via Levenshtein distance.
    
    Parameters:
        @SearchTags VARCHAR(50)   - Comma-separated tag search terms
        @ExactMatchOnly BIT       - 1 = exact match only, 0 = fuzzy match (default: 1)
        @Sensitivity INT          - Levenshtein distance threshold (default: 4)
    
    Returns:
        Table with Id INT - Matching tag Ids
    
    Author:     turkaffe
    Created:    2026-05-07
    Modified:   20260521 - Converted to inline table-valued function
    
    Example:
        SELECT * FROM dbo.GetTagsByString('python, c#', 0, 3);
*/
CREATE OR ALTER FUNCTION dbo.fn_GetTagsByString
(
    @SearchTags VARCHAR(50),
    @ExactMatchOnly BIT = 1,
    @Sensitivity INT = 4
)
RETURNS TABLE
AS
RETURN
(
    WITH search AS (
        SELECT TRIM(value) AS tag
        FROM STRING_SPLIT(@SearchTags, ',')
        WHERE LEN(TRIM(value)) > 0
    ),
    filtered AS (
        SELECT t.Id, t.Tag
        FROM dbo.Tags t
        JOIN search s ON t.tag LIKE s.tag + '%'
    ),
    ScoredTags AS (
        SELECT f.Id,
               dbo.Levenshtein(f.Tag, s.tag, @Sensitivity) AS MatchScore
        FROM filtered f
        CROSS APPLY (SELECT tag FROM search) s
    )
    SELECT st.Id
    FROM ScoredTags st
    WHERE (@ExactMatchOnly = 1 AND st.MatchScore = 0)
       OR (@ExactMatchOnly = 0 AND st.MatchScore <= @Sensitivity)
);
GO