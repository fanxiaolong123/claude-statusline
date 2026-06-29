#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // empty')

raw_cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
if [[ "$raw_cwd" == "$HOME" ]]; then
  cwd="~"
elif [[ "$raw_cwd" == "$HOME"/* ]]; then
  cwd="~${raw_cwd#$HOME}"
else
  cwd="$raw_cwd"
fi

branch=$(git -C "$raw_cwd" symbolic-ref --short HEAD 2>/dev/null)
[ -z "$branch" ] && branch=$(git -C "$raw_cwd" rev-parse --short HEAD 2>/dev/null)

pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx=""
if [ -n "$pct" ] && [ "$pct" != "null" ]; then
  ctx=$(printf '%.0f' "$pct")
fi

usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cost=""
if [ -n "$usd" ] && [ "$usd" != "null" ]; then
  cost=$(awk -v c="$usd" 'BEGIN{printf "$%.2f", c}')
fi

# effort: JSON gives low|medium|high|xhigh|max, but ultracode also reports as xhigh.
# Parse transcript to detect ultracode (and any later /effort switches).
effort=$(echo "$input" | jq -r '.effort.level // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  real_effort=$(jq -r 'select(.type=="user" and (.message.content|type)=="string"
    and (.message.content|startswith("<local-command-stdout>Set effort level to ")))
    | (.message.content|capture("Set effort level to (?<lvl>[a-z-]+)").lvl)' \
    "$transcript" 2>/dev/null | tail -1)
  [ -n "$real_effort" ] && effort="$real_effort"
fi
effort=$(echo "$effort" | tr '[:upper:]' '[:lower:]')

render_effort() {
  case "$1" in
    low)
      printf '\033[38;2;148;163;184mLOW\033[0m'
      ;;
    medium)
      printf '\033[38;2;56;189;248mMID\033[0m'
      ;;
    high)
      printf '\033[1m\033[38;2;167;139;250mHIGH\033[0m'
      ;;
    xhigh)
      printf '\033[1m\033[48;2;232;121;249m\033[38;2;255;255;255m X-HIGH \033[0m'
      ;;
    max)
      printf '\033[1m\033[48;2;239;68;68m\033[38;2;255;255;255m MAX \033[0m'
      ;;
    ultracode)
      perl -e '
        use utf8; binmode STDOUT, ":utf8";
        my $text = " \x{2726} ULTRA \x{2726} ";
        my @stops = ([96,165,250],[167,139,250],[232,121,249],[244,114,182]);
        my @c = split //, $text; my $n = @c;
        for my $i (0..$n-1) {
          my $t = $i/($n-1); my $seg = $#stops*$t;
          my $idx = int($seg); $idx = $#stops-1 if $idx >= $#stops;
          my $f = $seg-$idx; my @a = @{$stops[$idx]}; my @b = @{$stops[$idx+1]};
          my ($r,$g,$bl) = (int($a[0]+($b[0]-$a[0])*$f), int($a[1]+($b[1]-$a[1])*$f), int($a[2]+($b[2]-$a[2])*$f));
          printf "\033[1m\033[48;2;%d;%d;%dm\033[38;2;255;255;255m%s", $r, $g, $bl, $c[$i];
        }
        print "\033[0m";
      '
      ;;
  esac
}

parts=()
[ -n "$model" ]  && parts+=("${model}")
[ -n "$cwd" ]    && parts+=("CWD:${cwd}")
[ -n "$branch" ] && parts+=("Branch: ${branch}")
[ -n "$ctx" ]    && parts+=("Context:${ctx}%")
[ -n "$cost" ]   && parts+=("Cost:${cost}")

plain=""
for p in "${parts[@]}"; do
  if [ -z "$plain" ]; then plain="$p"
  else plain="${plain} | ${p}"
  fi
done

# Per-character truecolor gradient (pink → purple → cyan → mint, aurora-like)
gradient=$(python3 - "$plain" <<'PY'
import sys
s = sys.argv[1]
stops = [(0xff,0x6f,0xc6),(0xb4,0x7c,0xff),(0x60,0xd8,0xff),(0x6c,0xf5,0xa3)]
n = max(len(s)-1, 1)
def lerp(a,b,t): return int(a+(b-a)*t)
def at(t):
    if t>=1: return stops[-1]
    seg = t*(len(stops)-1)
    i = int(seg); f = seg-i
    a,b = stops[i], stops[i+1]
    return (lerp(a[0],b[0],f), lerp(a[1],b[1],f), lerp(a[2],b[2],f))
out=[]
for i,ch in enumerate(s):
    r,g,b = at(i/n)
    out.append(f'\x1b[38;2;{r};{g};{b}m{ch}')
out.append('\x1b[0m')
sys.stdout.write(''.join(out))
PY
)

effort_seg=""
if [ -n "$effort" ]; then
  effort_seg="$(render_effort "$effort") | "
fi

printf '%s%s\n' "$effort_seg" "$gradient"
