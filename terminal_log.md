

Welcome to 5.10.0-235.0.0.134.oe2203sp4.aarch64

System information as of time:  Tue May  5 02:12:16 PM CST 2026

System load:    1.52
Memory used:    57.8%
Swap used:      5.9%
Usage On:       14%
IP address:     192.168.90.141
Users online:   3
To run a command as administrator(user "root"),use "sudo <command>".
[s2412456@master_ubss1 svd]$ git init
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint: 
hint:   git config --global init.defaultBranch <name>
hint: 
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint: 
hint:   git branch -m <name>
Initialized empty Git repository in /home/s2412456/svd/.git/
[s2412456@master_ubss1 svd]$ git config user.name "Shang Wenxuan"
[s2412456@master_ubss1 svd]$ git config user.email "shangwenxuan.nku@gmail.com"
[s2412456@master_ubss1 svd]$ git add .
[s2412456@master_ubss1 svd]$ git commit -m "Initial commit: add SVD framework"
[master (root-commit) 4628997] Initial commit: add SVD framework
 11 files changed, 1090 insertions(+)
 create mode 100755 README.md
 create mode 100755 bidiagonalization.cpp
 create mode 100755 bidiagonalization.h
 create mode 100755 givens.h
 create mode 100755 gkh.cpp
 create mode 100755 gkh.h
 create mode 100755 main
 create mode 100755 main.cpp
 create mode 100755 matrix.h
 create mode 100755 qsub.sh
 create mode 100755 test.sh
[s2412456@master_ubss1 svd]$ git branch
* master
[s2412456@master_ubss1 svd]$ git checkout -b svd-simd
Switched to a new branch 'svd-simd'
[s2412456@master_ubss1 svd]$ git branch
  master
* svd-simd
[s2412456@master_ubss1 svd]$ git remote add origin https://github.com/ZR-1N/Parallel-Course-Experiments.git
[s2412456@master_ubss1 svd]$ git remote -v
origin  https://github.com/ZR-1N/Parallel-Course-Experiments.git (fetch)
origin  https://github.com/ZR-1N/Parallel-Course-Experiments.git (push)
[s2412456@master_ubss1 svd]$ git push -u origin svd-simd
Enumerating objects: 13, done.
Counting objects: 100% (13/13), done.
Delta compression using up to 8 threads
Compressing objects: 100% (13/13), done.
Writing objects: 100% (13/13), 32.45 KiB | 6.49 MiB/s, done.
Total 13 (delta 0), reused 0 (delta 0), pack-reused 0
remote: 
remote: Create a pull request for 'svd-simd' on GitHub by visiting:
remote:      https://github.com/ZR-1N/Parallel-Course-Experiments/pull/new/svd-simd
remote: 
To https://github.com/ZR-1N/Parallel-Course-Experiments.git
 * [new branch]      svd-simd -> svd-simd
Branch 'svd-simd' set up to track remote branch 'svd-simd' from 'origin'.
[s2412456@master_ubss1 svd]$ git branch
  master
* svd-simd
[s2412456@master_ubss1 svd]$ git status
On branch svd-simd
Your branch is up to date with 'origin/svd-simd'.

nothing to commit, working tree clean
[s2412456@master_ubss1 svd]$ sh test.sh 1 1
参数缺失
正确格式：bash test.sh [LAB] [NODES] [CORES] [-O <opt>] [-s <seed>]
  -O, --opt   可选，支持 O0/O1/O2/O3/Ofast 或 0/1/2/3/fast，默认 O2
  -s, --seed  可选，矩阵初始化种子，默认 20260409
[s2412456@master_ubss1 svd]$ bash test.sh 1 1
参数缺失
正确格式：bash test.sh [LAB] [NODES] [CORES] [-O <opt>] [-s <seed>]
  -O, --opt   可选，支持 O0/O1/O2/O3/Ofast 或 0/1/2/3/fast，默认 O2
  -s, --seed  可选，矩阵初始化种子，默认 20260409
[s2412456@master_ubss1 svd]$ sh test.sh 1 1 1
Submitted job with ID: 10754.master_ubss1
Compile opt: -O2
Seed: 20260409
Traceback (most recent call last):
  File "/usr/local/bin/pssh", line 106, in <module>
    opts, args = parse_args()
  File "/usr/local/bin/pssh", line 49, in parse_args
    parser = option_parser()
  File "/usr/local/bin/pssh", line 31, in option_parser
    parser = common_parser()
  File "/usr/local/lib/python3.9/site-packages/psshlib/cli.py", line 22, in common_parser
    version=version.VERSION)
AttributeError: module 'version' has no attribute 'VERSION'

Authorized users only. All activities may be monitored and reported.

Authorized users only. All activities may be monitored and reported.
Traceback (most recent call last):
  File "/usr/local/bin/pscp", line 92, in <module>
    opts, args = parse_args()
  File "/usr/local/bin/pscp", line 39, in parse_args
    parser = option_parser()
  File "/usr/local/bin/pscp", line 28, in option_parser
    parser = common_parser()
  File "/usr/local/lib/python3.9/site-packages/psshlib/cli.py", line 22, in common_parser
    version=version.VERSION)
AttributeError: module 'version' has no attribute 'VERSION'
=== 固定值 5x5 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 3.87116e-12
  relative recon error      : 2.76702e-13
  ||U^T U-I||_F             : 1.55583e-15
  ||V^T V-I||_F             : 1.42322e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.0201
  time gkh iteration(ms)    : 0.0165
  结果: PASS

=== 随机 8x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.12327e-14
  relative recon error      : 7.41499e-16
  ||U^T U-I||_F             : 1.80321e-15
  ||V^T V-I||_F             : 1.52765e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00952
  time gkh iteration(ms)    : 0.01562
  结果: PASS

=== 近秩亏损 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 2.09799e-13
  relative recon error      : 1.94571e-14
  ||U^T U-I||_F             : 2.46675e-15
  ||V^T V-I||_F             : 2.23351e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01017
  time gkh iteration(ms)    : 0.01821
  结果: PASS

=== 随机 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.32266e-11
  relative recon error      : 6.32491e-13
  ||U^T U-I||_F             : 2.43461e-15
  ||V^T V-I||_F             : 1.83272e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00739
  time gkh iteration(ms)    : 0.01568
  结果: PASS

=== 随机 1000x1000 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.84725e-10
  relative recon error      : 3.19182e-13
  ||U^T U-I||_F             : 2.38363e-13
  ||V^T V-I||_F             : 2.37297e-13
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 6781.5
  time gkh iteration(ms)    : 40642.9
  结果: PASS

==============================
随机种子基值: 20260409
总上二对角化耗时(ms): 6781.55
总GKH迭代耗时(ms): 40642.9
通过: 5 / 5

Authorized users only. All activities may be monitored and reported.
[s2412456@master_ubss1 svd]$ qstat
Job ID                    Name             User            Time Use S Queue
------------------------- ---------------- --------------- -------- - -----
10754.master_ubss1         qsub             s2412456        00:00:52 C dque           
[s2412456@master_ubss1 svd]$ qstat -n

master_ubss1: 
                                                                                  Req'd       Req'd       Elap
Job ID                  Username    Queue    Jobname          SessID  NDS   TSK   Memory      Time    S   Time
----------------------- ----------- -------- ---------------- ------ ----- ------ --------- --------- - ---------
10754.master_ubss1      s2412456    dque     qsub             161136     1      1       --        --  C       -- 
   master_ubss2/0
[s2412456@master_ubss1 svd]$ cat test.o*
=== 固定值 5x5 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 3.87116e-12
  relative recon error      : 2.76702e-13
  ||U^T U-I||_F             : 1.55583e-15
  ||V^T V-I||_F             : 1.42322e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.0201
  time gkh iteration(ms)    : 0.0165
  结果: PASS

=== 随机 8x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.12327e-14
  relative recon error      : 7.41499e-16
  ||U^T U-I||_F             : 1.80321e-15
  ||V^T V-I||_F             : 1.52765e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00952
  time gkh iteration(ms)    : 0.01562
  结果: PASS

=== 近秩亏损 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 2.09799e-13
  relative recon error      : 1.94571e-14
  ||U^T U-I||_F             : 2.46675e-15
  ||V^T V-I||_F             : 2.23351e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01017
  time gkh iteration(ms)    : 0.01821
  结果: PASS

=== 随机 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.32266e-11
  relative recon error      : 6.32491e-13
  ||U^T U-I||_F             : 2.43461e-15
  ||V^T V-I||_F             : 1.83272e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00739
  time gkh iteration(ms)    : 0.01568
  结果: PASS

=== 随机 1000x1000 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.84725e-10
  relative recon error      : 3.19182e-13
  ||U^T U-I||_F             : 2.38363e-13
  ||V^T V-I||_F             : 2.37297e-13
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 6781.5
  time gkh iteration(ms)    : 40642.9
  结果: PASS

==============================
随机种子基值: 20260409
总上二对角化耗时(ms): 6781.55
总GKH迭代耗时(ms): 40642.9
通过: 5 / 5

Authorized users only. All activities may be monitored and reported.
[s2412456@master_ubss1 svd]$ cat test.e*
Traceback (most recent call last):
  File "/usr/local/bin/pssh", line 106, in <module>
    opts, args = parse_args()
  File "/usr/local/bin/pssh", line 49, in parse_args
    parser = option_parser()
  File "/usr/local/bin/pssh", line 31, in option_parser
    parser = common_parser()
  File "/usr/local/lib/python3.9/site-packages/psshlib/cli.py", line 22, in common_parser
    version=version.VERSION)
AttributeError: module 'version' has no attribute 'VERSION'

Authorized users only. All activities may be monitored and reported.

Authorized users only. All activities may be monitored and reported.
Traceback (most recent call last):
  File "/usr/local/bin/pscp", line 92, in <module>
    opts, args = parse_args()
  File "/usr/local/bin/pscp", line 39, in parse_args
    parser = option_parser()
  File "/usr/local/bin/pscp", line 28, in option_parser
    parser = common_parser()
  File "/usr/local/lib/python3.9/site-packages/psshlib/cli.py", line 22, in common_parser
    version=version.VERSION)
AttributeError: module 'version' has no attribute 'VERSION'
[s2412456@master_ubss1 svd]$ git add .
[s2412456@master_ubss1 svd]$ git commit -m "baseline serial SVD framework: all tests pass"
[svd-simd a3c5661] baseline serial SVD framework: all tests pass
 2 files changed, 96 insertions(+)
 create mode 100644 test.e
 create mode 100644 test.o
[s2412456@master_ubss1 svd]$ git status
On branch svd-simd
Your branch is ahead of 'origin/svd-simd' by 1 commit.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
[s2412456@master_ubss1 svd]$ git push origin svd-simd
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 1.23 KiB | 1.23 MiB/s, done.
Total 4 (delta 1), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (1/1), completed with 1 local object.
To https://github.com/ZR-1N/Parallel-Course-Experiments.git
   4628997..a3c5661  svd-simd -> svd-simd
[s2412456@master_ubss1 svd]$ dir
bidiagonalization.cpp  files     gkh.cpp  main      matrix.h  README.md  test.o
bidiagonalization.h    givens.h  gkh.h    main.cpp  qsub.sh   test.e     test.sh
[s2412456@master_ubss1 svd]$ sh test.sh 1 1 1
gkh.cpp:9:10: fatal error: immintrin.h: No such file or directory
    9 | #include <immintrin.h> //for AVX2
      |          ^~~~~~~~~~~~~
compilation terminated.
Submitted job with ID: 10772.master_ubss1
Compile opt: -O2
Seed: 20260409
Traceback (most recent call last):
  File "/usr/local/bin/pssh", line 106, in <module>
    opts, args = parse_args()
  File "/usr/local/bin/pssh", line 49, in parse_args
    parser = option_parser()
  File "/usr/local/bin/pssh", line 31, in option_parser
    parser = common_parser()
  File "/usr/local/lib/python3.9/site-packages/psshlib/cli.py", line 22, in common_parser
    version=version.VERSION)
AttributeError: module 'version' has no attribute 'VERSION'

Authorized users only. All activities may be monitored and reported.

Authorized users only. All activities may be monitored and reported.
Traceback (most recent call last):
  File "/usr/local/bin/pscp", line 92, in <module>
    opts, args = parse_args()
  File "/usr/local/bin/pscp", line 39, in parse_args
    parser = option_parser()
  File "/usr/local/bin/pscp", line 28, in option_parser
    parser = common_parser()
  File "/usr/local/lib/python3.9/site-packages/psshlib/cli.py", line 22, in common_parser
    version=version.VERSION)
AttributeError: module 'version' has no attribute 'VERSION'
=== 固定值 5x5 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 3.87116e-12
  relative recon error      : 2.76702e-13
  ||U^T U-I||_F             : 1.55583e-15
  ||V^T V-I||_F             : 1.42322e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01999
  time gkh iteration(ms)    : 0.01633
  结果: PASS

=== 随机 8x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.12327e-14
  relative recon error      : 7.41499e-16
  ||U^T U-I||_F             : 1.80321e-15
  ||V^T V-I||_F             : 1.52765e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00978
  time gkh iteration(ms)    : 0.0155
  结果: PASS

=== 近秩亏损 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 2.09799e-13
  relative recon error      : 1.94571e-14
  ||U^T U-I||_F             : 2.46675e-15
  ||V^T V-I||_F             : 2.23351e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01043
  time gkh iteration(ms)    : 0.01782
  结果: PASS

=== 随机 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.32266e-11
  relative recon error      : 6.32491e-13
  ||U^T U-I||_F             : 2.43461e-15
  ||V^T V-I||_F             : 1.83272e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00727
  time gkh iteration(ms)    : 0.015541
  结果: PASS

=== 随机 1000x1000 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.84725e-10
  relative recon error      : 3.19182e-13
  ||U^T U-I||_F             : 2.38363e-13
  ||V^T V-I||_F             : 2.37297e-13
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 7039.75
  time gkh iteration(ms)    : 43475.6
  结果: PASS

==============================
随机种子基值: 20260409
总上二对角化耗时(ms): 7039.79
总GKH迭代耗时(ms): 43475.7
通过: 5 / 5

Authorized users only. All activities may be monitored and reported.
[s2412456@master_ubss1 svd]$ cat test.o*
=== 固定值 5x5 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 3.87116e-12
  relative recon error      : 2.76702e-13
  ||U^T U-I||_F             : 1.55583e-15
  ||V^T V-I||_F             : 1.42322e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01999
  time gkh iteration(ms)    : 0.01633
  结果: PASS

=== 随机 8x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.12327e-14
  relative recon error      : 7.41499e-16
  ||U^T U-I||_F             : 1.80321e-15
  ||V^T V-I||_F             : 1.52765e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00978
  time gkh iteration(ms)    : 0.0155
  结果: PASS

=== 近秩亏损 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 2.09799e-13
  relative recon error      : 1.94571e-14
  ||U^T U-I||_F             : 2.46675e-15
  ||V^T V-I||_F             : 2.23351e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01043
  time gkh iteration(ms)    : 0.01782
  结果: PASS

=== 随机 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.32266e-11
  relative recon error      : 6.32491e-13
  ||U^T U-I||_F             : 2.43461e-15
  ||V^T V-I||_F             : 1.83272e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00727
  time gkh iteration(ms)    : 0.015541
  结果: PASS

=== 随机 1000x1000 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.84725e-10
  relative recon error      : 3.19182e-13
  ||U^T U-I||_F             : 2.38363e-13
  ||V^T V-I||_F             : 2.37297e-13
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 7039.75
  time gkh iteration(ms)    : 43475.6
  结果: PASS

==============================
随机种子基值: 20260409
总上二对角化耗时(ms): 7039.79
总GKH迭代耗时(ms): 43475.7
通过: 5 / 5

Authorized users only. All activities may be monitored and reported.
[s2412456@master_ubss1 svd]$ sh test.sh 1 1 1
Submitted job with ID: 10778.master_ubss1
Compile opt: -O2
Seed: 20260409
Traceback (most recent call last):
  File "/usr/local/bin/pssh", line 106, in <module>
    opts, args = parse_args()
  File "/usr/local/bin/pssh", line 49, in parse_args
    parser = option_parser()
  File "/usr/local/bin/pssh", line 31, in option_parser
    parser = common_parser()
  File "/usr/local/lib/python3.9/site-packages/psshlib/cli.py", line 22, in common_parser
    version=version.VERSION)
AttributeError: module 'version' has no attribute 'VERSION'

Authorized users only. All activities may be monitored and reported.

Authorized users only. All activities may be monitored and reported.
Traceback (most recent call last):
  File "/usr/local/bin/pscp", line 92, in <module>
    opts, args = parse_args()
  File "/usr/local/bin/pscp", line 39, in parse_args
    parser = option_parser()
  File "/usr/local/bin/pscp", line 28, in option_parser
    parser = common_parser()
  File "/usr/local/lib/python3.9/site-packages/psshlib/cli.py", line 22, in common_parser
    version=version.VERSION)
AttributeError: module 'version' has no attribute 'VERSION'
=== 固定值 5x5 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 3.87116e-12
  relative recon error      : 2.76702e-13
  ||U^T U-I||_F             : 1.55583e-15
  ||V^T V-I||_F             : 1.42322e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.02019
  time gkh iteration(ms)    : 0.02693
  结果: PASS

=== 随机 8x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.12327e-14
  relative recon error      : 7.41499e-16
  ||U^T U-I||_F             : 1.80321e-15
  ||V^T V-I||_F             : 1.52765e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.0099
  time gkh iteration(ms)    : 0.01545
  结果: PASS

=== 近秩亏损 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 2.09799e-13
  relative recon error      : 1.94571e-14
  ||U^T U-I||_F             : 2.46675e-15
  ||V^T V-I||_F             : 2.23351e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01145
  time gkh iteration(ms)    : 0.01759
  结果: PASS

=== 随机 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.32266e-11
  relative recon error      : 6.32491e-13
  ||U^T U-I||_F             : 2.43461e-15
  ||V^T V-I||_F             : 1.83272e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00759
  time gkh iteration(ms)    : 0.01516
  结果: PASS

=== 随机 1000x1000 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.84725e-10
  relative recon error      : 3.19182e-13
  ||U^T U-I||_F             : 2.38363e-13
  ||V^T V-I||_F             : 2.37297e-13
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 6717.58
  time gkh iteration(ms)    : 27859.6
  结果: PASS

==============================
随机种子基值: 20260409
总上二对角化耗时(ms): 6717.63
总GKH迭代耗时(ms): 27859.7
通过: 5 / 5

Authorized users only. All activities may be monitored and reported.
[s2412456@master_ubss1 svd]$ cat test.o*
=== 固定值 5x5 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 3.87116e-12
  relative recon error      : 2.76702e-13
  ||U^T U-I||_F             : 1.55583e-15
  ||V^T V-I||_F             : 1.42322e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.02019
  time gkh iteration(ms)    : 0.02693
  结果: PASS

=== 随机 8x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.12327e-14
  relative recon error      : 7.41499e-16
  ||U^T U-I||_F             : 1.80321e-15
  ||V^T V-I||_F             : 1.52765e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.0099
  time gkh iteration(ms)    : 0.01545
  结果: PASS

=== 近秩亏损 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 2.09799e-13
  relative recon error      : 1.94571e-14
  ||U^T U-I||_F             : 2.46675e-15
  ||V^T V-I||_F             : 2.23351e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01145
  time gkh iteration(ms)    : 0.01759
  结果: PASS

=== 随机 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.32266e-11
  relative recon error      : 6.32491e-13
  ||U^T U-I||_F             : 2.43461e-15
  ||V^T V-I||_F             : 1.83272e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00759
  time gkh iteration(ms)    : 0.01516
  结果: PASS

=== 随机 1000x1000 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.84725e-10
  relative recon error      : 3.19182e-13
  ||U^T U-I||_F             : 2.38363e-13
  ||V^T V-I||_F             : 2.37297e-13
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 6717.58
  time gkh iteration(ms)    : 27859.6
  结果: PASS

==============================
随机种子基值: 20260409
总上二对角化耗时(ms): 6717.63
总GKH迭代耗时(ms): 27859.7
通过: 5 / 5

Authorized users only. All activities may be monitored and reported.
[s2412456@master_ubss1 svd]$ sh test.sh 1 1 1
Submitted job with ID: 10803.master_ubss1
Compile opt: -O2
Seed: 20260409
Traceback (most recent call last):
  File "/usr/local/bin/pssh", line 106, in <module>
    opts, args = parse_args()
  File "/usr/local/bin/pssh", line 49, in parse_args
    parser = option_parser()
  File "/usr/local/bin/pssh", line 31, in option_parser
    parser = common_parser()
  File "/usr/local/lib/python3.9/site-packages/psshlib/cli.py", line 22, in common_parser
    version=version.VERSION)
AttributeError: module 'version' has no attribute 'VERSION'

Authorized users only. All activities may be monitored and reported.

Authorized users only. All activities may be monitored and reported.
Traceback (most recent call last):
  File "/usr/local/bin/pscp", line 92, in <module>
    opts, args = parse_args()
  File "/usr/local/bin/pscp", line 39, in parse_args
    parser = option_parser()
  File "/usr/local/bin/pscp", line 28, in option_parser
    parser = common_parser()
  File "/usr/local/lib/python3.9/site-packages/psshlib/cli.py", line 22, in common_parser
    version=version.VERSION)
AttributeError: module 'version' has no attribute 'VERSION'
=== 固定值 5x5 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 3.87116e-12
  relative recon error      : 2.76702e-13
  ||U^T U-I||_F             : 1.55583e-15
  ||V^T V-I||_F             : 1.42322e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01075
  time gkh iteration(ms)    : 0.03214
  结果: PASS

=== 随机 8x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.12327e-14
  relative recon error      : 7.41499e-16
  ||U^T U-I||_F             : 1.80321e-15
  ||V^T V-I||_F             : 1.52765e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00999
  time gkh iteration(ms)    : 0.01554
  结果: PASS

=== 近秩亏损 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 2.09799e-13
  relative recon error      : 1.94571e-14
  ||U^T U-I||_F             : 2.46675e-15
  ||V^T V-I||_F             : 2.23351e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01041
  time gkh iteration(ms)    : 0.01767
  结果: PASS

=== 随机 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.32266e-11
  relative recon error      : 6.32491e-13
  ||U^T U-I||_F             : 2.43461e-15
  ||V^T V-I||_F             : 1.83272e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00688
  time gkh iteration(ms)    : 0.01493
  结果: PASS

=== 随机 1000x1000 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.84725e-10
  relative recon error      : 3.19182e-13
  ||U^T U-I||_F             : 2.38363e-13
  ||V^T V-I||_F             : 2.37297e-13
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 7981.55
  time gkh iteration(ms)    : 31966.6
  结果: PASS

==============================
随机种子基值: 20260409
总上二对角化耗时(ms): 7981.59
总GKH迭代耗时(ms): 31966.6
通过: 5 / 5

Authorized users only. All activities may be monitored and reported.
[s2412456@master_ubss1 svd]$ cat test.o*
=== 固定值 5x5 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 3.87116e-12
  relative recon error      : 2.76702e-13
  ||U^T U-I||_F             : 1.55583e-15
  ||V^T V-I||_F             : 1.42322e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01075
  time gkh iteration(ms)    : 0.03214
  结果: PASS

=== 随机 8x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.12327e-14
  relative recon error      : 7.41499e-16
  ||U^T U-I||_F             : 1.80321e-15
  ||V^T V-I||_F             : 1.52765e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00999
  time gkh iteration(ms)    : 0.01554
  结果: PASS

=== 近秩亏损 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 2.09799e-13
  relative recon error      : 1.94571e-14
  ||U^T U-I||_F             : 2.46675e-15
  ||V^T V-I||_F             : 2.23351e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.01041
  time gkh iteration(ms)    : 0.01767
  结果: PASS

=== 随机 10x8 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.32266e-11
  relative recon error      : 6.32491e-13
  ||U^T U-I||_F             : 2.43461e-15
  ||V^T V-I||_F             : 1.83272e-15
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 0.00688
  time gkh iteration(ms)    : 0.01493
  结果: PASS

=== 随机 1000x1000 ===
  converged                 : yes
  ||A-U*S*V^T||_F           : 1.84725e-10
  relative recon error      : 3.19182e-13
  ||U^T U-I||_F             : 2.38363e-13
  ||V^T V-I||_F             : 2.37297e-13
  diagonal structure error  : 0
  descending order error    : 0
  nonnegative diagonal      : yes
  time bidiagonalization(ms): 7981.55
  time gkh iteration(ms)    : 31966.6
  结果: PASS

==============================
随机种子基值: 20260409
总上二对角化耗时(ms): 7981.59
总GKH迭代耗时(ms): 31966.6
通过: 5 / 5

Authorized users only. All activities may be monitored and reported.