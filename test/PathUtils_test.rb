require "test/unit"
require "PathUtils"

class PathUtils_test < Test::Unit::TestCase

    def test_splitPath
        assert_equal(["", "foo", "bar", "baz.mp3" ], PathUtils.splitPath("/foo/bar/baz.mp3"))
        assert_equal(["foo", "bar", "baz.mp3" ], PathUtils.splitPath("foo/bar/baz.mp3"))
        assert_equal([".", "foo", "bar", "baz.mp3" ], PathUtils.splitPath("./foo/bar/baz.mp3"))
    end

    def test_relativePath
        assert_equal("foo/bar.mp3", PathUtils.relativePath("/music/foo/bar.mp3", "/music"))
        assert_equal("foo/bar.mp3", PathUtils.relativePath("/music/foo/bar.mp3", "/music/"))
        assert_equal("foo/bar.mp3", PathUtils.relativePath("music/foo/bar.mp3", "music/"))
        assert_equal("foo/bar.mp3", PathUtils.relativePath("./music/foo/bar.mp3", "music/"))
        assert_equal("foo/bar.mp3", PathUtils.relativePath("./music/foo/bar.mp3", "./music/"))
        assert_equal("music/foo/bar.mp3", PathUtils.relativePath("music/foo/bar.mp3", ""))
        assert_equal("music/foo/bar.mp3", PathUtils.relativePath("/music/foo/bar.mp3", "/"))
        assert_equal("", PathUtils.relativePath("/foo/bar.mp3", "/moo"))

        # Should pass
        # assert_equal("/music/foo/bar.mp3", PathUtils.relativePath("/music/foo/bar.mp3", ""))
    end

    def test_replaceExtension
        assert_equal("foo.bar", PathUtils.replaceExtension("foo.baz", "baz", "bar"))
        assert_equal("foo.baz", PathUtils.replaceExtension("foo.baz", "yada", "bar"))
        assert_equal("foo", PathUtils.replaceExtension("foo", "yada", "bar"))
        assert_equal("/moo/foo.bar", PathUtils.replaceExtension("/moo/foo.baz", "baz", "bar"))
        assert_equal("/moo/foo.baz", PathUtils.replaceExtension("/moo/foo.baz", "yada", "bar"))
        assert_equal("/moo/foo", PathUtils.replaceExtension("/moo/foo", "yada", "bar"))
    end

    def test_computeRelative
        assert_equal("/x/y/c/d.f", PathUtils.computeRelative("/a/b/c/d.e", "/a/b", "/x/y", "e", "f"))
        assert_equal("/x/y/c/d.e", PathUtils.computeRelative("/a/b/c/d.e", "/a/b", "/x/y"))
        assert_equal("x/y/c/d.f", PathUtils.computeRelative("a/b/c/d.e", "a/b", "x/y", "e", "f"))
        assert_equal("x/y/c/d.e", PathUtils.computeRelative("a/b/c/d.e", "a/b", "x/y"))
        assert_equal("", PathUtils.computeRelative("/a/b/c/d.e", "/c/d", "/x/y", "e", "f"))
    end

    def test_extension
        assert_equal("wma", PathUtils.extension("foo.wma"))
        assert_equal("wma", PathUtils.extension("/music/bar/foo.wma"))
        assert_equal("", PathUtils.extension("/music/bar/foo"))
    end

    def test_escape
        assert_equal("Foo\\ Bar", PathUtils.escape("Foo Bar"))
        assert_equal("Foo\\&Bar", PathUtils.escape("Foo&Bar"))
        assert_equal("Foo\\&Bar", PathUtils.escape("Foo&Bar"))
        assert_equal("Foo\\(Bar", PathUtils.escape("Foo(Bar"))
        assert_equal("Foo\\)Bar", PathUtils.escape("Foo)Bar"))
        assert_equal("Foo\\;Bar", PathUtils.escape("Foo;Bar"))
        assert_equal("Foo\\,Bar", PathUtils.escape("Foo,Bar"))
        assert_equal("Foo\\'Bar", PathUtils.escape("Foo'Bar"))
        assert_equal("Foo\\\"Bar", PathUtils.escape("Foo\"Bar"))
        assert_equal("Foo\\`Bar", PathUtils.escape("Foo`Bar"))
    end

    # These require file system cooperation

    def test_searchList
    end

    def test_isDeadLink
    end
end